import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { AggregateField, FieldValue, getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { getStorage } from "firebase-admin/storage";
import { setGlobalOptions } from "firebase-functions/v2";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { onDocumentCreated, onDocumentDeleted, onDocumentUpdated, onDocumentWritten } from "firebase-functions/v2/firestore";

initializeApp();
setGlobalOptions({ region: "europe-west1", maxInstances: 10 });
const db = getFirestore();

type Kind = "join_request" | "join_approved" | "join_rejected" | "new_post";
type P = { classId: string; classTitle: string; name: string; postTitle: string };

const TXT: Record<string, Record<Kind, (p: P) => [string, string]>> = {
  en: {
    join_request: (p) => ["New join request", `${p.name} asked to join ${p.classTitle}`],
    join_approved: (p) => ["You’re in", p.classTitle],
    join_rejected: (p) => ["Request not accepted", p.classTitle],
    new_post: (p) => [p.classTitle, p.postTitle],
  },
  fr: {
    join_request: (p) => ["Nouvelle demande", `${p.name} veut rejoindre ${p.classTitle}`],
    join_approved: (p) => ["Vous êtes inscrit", p.classTitle],
    join_rejected: (p) => ["Demande non acceptée", p.classTitle],
    new_post: (p) => [p.classTitle, p.postTitle],
  },
  ar: {
    join_request: (p) => ["طلب انضمام جديد", `${p.name} يطلب الانضمام إلى ${p.classTitle}`],
    join_approved: (p) => ["تم قبولك", p.classTitle],
    join_rejected: (p) => ["لم يتم قبول طلبك", p.classTitle],
    new_post: (p) => [p.classTitle, p.postTitle],
  },
};

/** Writes the in-app notification and sends the push message in the user's language. */
async function notify(uid: string, kind: Kind, p: P): Promise<void> {
  const u = await db.doc(`users/${uid}`).get();
  if (!u.exists) return;
  const loc = u.get("locale");
  const lang = loc === "ar" || loc === "fr" ? loc : "en";
  const [title, body] = TXT[lang][kind](p);
  await db.collection(`users/${uid}/notifications`).add({
    kind,
    classId: p.classId,
    classTitle: p.classTitle,
    name: p.name,
    postTitle: p.postTitle,
    read: false,
    createdAt: FieldValue.serverTimestamp(),
  });
  const tokens = await db.collection(`users/${uid}/tokens`).get();
  if (tokens.empty) return;
  const res = await getMessaging().sendEachForMulticast({
    tokens: tokens.docs.map((d) => d.id),
    notification: { title, body },
    data: { classId: p.classId },
    android: { priority: "high" },
  });
  res.responses.forEach((r, i) => {
    const code = r.error?.code ?? "";
    if (!r.success && (code === "messaging/registration-token-not-registered" || code === "messaging/invalid-registration-token")) {
      void tokens.docs[i].ref.delete();
    }
  });
}

const bump = (classId: string, data: Record<string, unknown>) => db.doc(`classes/${classId}`).update(data).catch(() => undefined);

// ---------- membership counters and notifications ----------
export const onMemberCreated = onDocumentCreated("classes/{classId}/members/{memberId}", async (e) => {
  const m = e.data?.data();
  if (!m) return;
  await bump(e.params.classId, { pendingCount: FieldValue.increment(1) });
  await notify(m.tutorId, "join_request", { classId: e.params.classId, classTitle: m.classTitle, name: m.name, postTitle: "" });
});

export const onMemberUpdated = onDocumentUpdated("classes/{classId}/members/{memberId}", async (e) => {
  const before = e.data?.before.data();
  const after = e.data?.after.data();
  if (!before || !after || before.status === after.status || before.status !== "pending") return;
  const p: P = { classId: e.params.classId, classTitle: after.classTitle, name: after.name, postTitle: "" };
  if (after.status === "approved") {
    await bump(e.params.classId, { pendingCount: FieldValue.increment(-1), memberCount: FieldValue.increment(1) });
    await notify(after.uid, "join_approved", p);
  } else if (after.status === "rejected") {
    await bump(e.params.classId, { pendingCount: FieldValue.increment(-1) });
    await notify(after.uid, "join_rejected", p);
  }
});

export const onMemberDeleted = onDocumentDeleted("classes/{classId}/members/{memberId}", async (e) => {
  const m = e.data?.data();
  if (!m) return;
  if (m.status === "approved") await bump(e.params.classId, { memberCount: FieldValue.increment(-1) });
  if (m.status === "pending") await bump(e.params.classId, { pendingCount: FieldValue.increment(-1) });
});

// ---------- posts ----------
export const onPostCreated = onDocumentCreated("classes/{classId}/posts/{postId}", async (e) => {
  const post = e.data?.data();
  if (!post) return;
  const cls = await db.doc(`classes/${e.params.classId}`).get();
  const members = await db.collection(`classes/${e.params.classId}/members`).where("status", "==", "approved").get();
  const p: P = { classId: e.params.classId, classTitle: cls.get("title") ?? "", name: "", postTitle: post.title ?? "" };
  const ids = members.docs.map((d) => d.id);
  for (let i = 0; i < ids.length; i += 20) {
    await Promise.all(ids.slice(i, i + 20).map((id) => notify(id, "new_post", p).catch(() => undefined)));
  }
});

export const onPostDeleted = onDocumentDeleted("classes/{classId}/posts/{postId}", async (e) => {
  await db.recursiveDelete(db.doc(`classes/${e.params.classId}/posts/${e.params.postId}`));
  const path = e.data?.get("filePath");
  if (typeof path === "string" && path.length > 0) {
    await getStorage().bucket().file(path).delete({ ignoreNotFound: true }).catch(() => undefined);
  }
});

export const onReactionWritten = onDocumentWritten("classes/{classId}/posts/{postId}/reactions/{uid}", async (e) => {
  const { classId, postId } = e.params;
  const snap = await db.collection(`classes/${classId}/posts/${postId}/reactions`).get();
  const counts: Record<string, number> = {};
  snap.docs.forEach((d) => {
    const k = d.get("emoji") as string;
    counts[k] = (counts[k] ?? 0) + 1;
  });
  await db.doc(`classes/${classId}/posts/${postId}`).update({ reactionCounts: counts }).catch(() => undefined);
});

export const onVoteWritten = onDocumentWritten("classes/{classId}/posts/{postId}/votes/{uid}", async (e) => {
  const { classId, postId } = e.params;
  const snap = await db.collection(`classes/${classId}/posts/${postId}/votes`).get();
  const counts: Record<string, number> = {};
  snap.docs.forEach((d) => ((d.get("options") as string[]) ?? []).forEach((o) => (counts[o] = (counts[o] ?? 0) + 1)));
  await db.doc(`classes/${classId}/posts/${postId}`).update({ pollCounts: counts }).catch(() => undefined);
});

export const onCommentWritten = onDocumentWritten("classes/{classId}/posts/{postId}/comments/{commentId}", async (e) => {
  const { classId, postId } = e.params;
  const agg = await db.collection(`classes/${classId}/posts/${postId}/comments`).count().get();
  await db.doc(`classes/${classId}/posts/${postId}`).update({ commentCount: agg.data().count }).catch(() => undefined);
});

// ---------- reviews ----------
export const onReviewWritten = onDocumentWritten("tutors/{tutorId}/reviews/{uid}", async (e) => {
  const agg = await db
    .collection(`tutors/${e.params.tutorId}/reviews`)
    .aggregate({ n: AggregateField.count(), avg: AggregateField.average("rating") })
    .get();
  const d = agg.data();
  await db
    .doc(`tutors/${e.params.tutorId}`)
    .update({ ratingCount: d.n, ratingAvg: Math.round((d.avg ?? 0) * 10) / 10 })
    .catch(() => undefined);
});

// ---------- user data rights ----------
const replacer = (_k: string, v: unknown) =>
  v && typeof v === "object" && typeof (v as { toDate?: unknown }).toDate === "function" ? (v as { toDate: () => Date }).toDate().toISOString() : v;

export const exportMyData = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in first.");
  const list = async (q: FirebaseFirestore.Query) => (await q.get()).docs.map((d) => ({ id: d.id, ...d.data() }));
  const data = {
    exportedAt: new Date().toISOString(),
    profile: (await db.doc(`users/${uid}`).get()).data() ?? null,
    tutorProfile: (await db.doc(`tutors/${uid}`).get()).data() ?? null,
    children: await list(db.collection(`users/${uid}/children`)),
    blockedUsers: await list(db.collection(`users/${uid}/blocks`)),
    memberships: await list(db.collectionGroup("members").where("uid", "==", uid)),
    comments: await list(db.collectionGroup("comments").where("authorId", "==", uid)),
    reviews: await list(db.collectionGroup("reviews").where("authorId", "==", uid)),
    classesCreated: await list(db.collection("classes").where("tutorId", "==", uid)),
    notifications: await list(db.collection(`users/${uid}/notifications`).limit(200)),
  };
  return JSON.stringify(data, replacer, 2);
});

export const deleteAccount = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in first.");

  const del = async (q: FirebaseFirestore.Query) => {
    const s = await q.get();
    await Promise.all(s.docs.map((d) => d.ref.delete()));
  };
  await del(db.collectionGroup("members").where("uid", "==", uid));
  await del(db.collectionGroup("comments").where("authorId", "==", uid));
  await del(db.collectionGroup("reviews").where("authorId", "==", uid));
  await del(db.collectionGroup("reactions").where("uid", "==", uid));
  await del(db.collectionGroup("votes").where("uid", "==", uid));

  const mine = await db.collection("classes").where("tutorId", "==", uid).get();
  for (const c of mine.docs) {
    await getStorage().bucket().deleteFiles({ prefix: `classes/${c.id}/` }).catch(() => undefined);
    await db.recursiveDelete(c.ref);
  }
  await db.recursiveDelete(db.doc(`tutors/${uid}`));
  await db.recursiveDelete(db.doc(`users/${uid}`));
  await getAuth().deleteUser(uid);
  return { ok: true };
});
