const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { readFileSync } = require('fs');
const { test, before, after, beforeEach } = require('node:test');
const fb = require('firebase/compat/app');
require('firebase/compat/firestore');

const firebase = fb.default || fb;
const NOW = () => firebase.firestore.FieldValue.serverTimestamp();
let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-qarini',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8') },
  });
});
after(async () => env.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await db.doc('users/tutor1').set({ name: 'Karim Benali', role: 'tutor' });
    await db.doc('users/alice').set({ name: 'Amina Haddad', role: 'student' });
    await db.doc('users/bob').set({ name: 'Yacine Messaoud', role: 'student' });
    await db.doc('tutors/tutor1').set({ name: 'Karim Benali', ratingAvg: 0, ratingCount: 0 });
    await db.doc('classes/c1').set({ tutorId: 'tutor1', tutorName: 'Karim Benali', title: 'Maths Bac 2027', status: 'open', memberCount: 1, capacity: 10 });
    await db.doc('classes/full').set({ tutorId: 'tutor1', tutorName: 'Karim Benali', title: 'Physique Bac', status: 'open', memberCount: 5, capacity: 5 });
    await db.doc('classes/c1/members/alice').set({ uid: 'alice', status: 'approved', tutorId: 'tutor1' });
    await db.doc('classes/c1/members/bob').set({ uid: 'bob', status: 'pending', tutorId: 'tutor1' });
    await db.doc('classes/c1/posts/p1').set({ type: 'announcement', title: 'Cours annulé', commentsEnabled: false, authorId: 'tutor1' });
    await db.doc('classes/c1/posts/p2').set({ type: 'announcement', title: 'Devoir', commentsEnabled: true, authorId: 'tutor1' });
  });
});

const as = (uid) => env.authenticatedContext(uid, { email_verified: true }).firestore();

test('a user cannot read another user profile', async () => {
  await assertFails(as('alice').doc('users/bob').get());
  await assertSucceeds(as('alice').doc('users/alice').get());
});

test('a user cannot change their own role', async () => {
  await assertFails(as('alice').doc('users/alice').update({ role: 'tutor' }));
});

test('a student cannot create a class', async () => {
  await assertFails(as('alice').doc('classes/x').set({ tutorId: 'alice', tutorName: 'Amina Haddad', title: 'Fake class', description: '', subject: 'math', level: 'bac', price: 0, priceUnit: 'month', wilaya: '9', commune: '', mode: 'online', schedule: '', capacity: 5, status: 'open', memberCount: 0, pendingCount: 0, createdAt: NOW() }));
});

test('posts are readable only by the tutor and approved members', async () => {
  await assertSucceeds(as('alice').doc('classes/c1/posts/p1').get());
  await assertSucceeds(as('tutor1').doc('classes/c1/posts/p1').get());
  await assertFails(as('bob').doc('classes/c1/posts/p1').get());
  await env.withSecurityRulesDisabled(async (ctx) => ctx.firestore().doc('users/eve').set({ name: 'Eve', role: 'student' }));
  await assertFails(as('eve').doc('classes/c1/posts/p1').get());
});

test('a student cannot publish a post', async () => {
  await assertFails(as('alice').doc('classes/c1/posts/new').set({ type: 'announcement', title: 'Hi', body: '', commentsEnabled: true, authorId: 'alice', authorName: 'Amina Haddad', createdAt: NOW() }));
});

test('the tutor can publish a post', async () => {
  await assertSucceeds(as('tutor1').doc('classes/c1/posts/new').set({ type: 'announcement', title: 'Salam', body: '', commentsEnabled: true, authorId: 'tutor1', authorName: 'Karim Benali', createdAt: NOW() }));
});

test('a member cannot approve themselves', async () => {
  await assertFails(as('bob').doc('classes/c1/members/bob').update({ status: 'approved', decidedAt: NOW() }));
  await assertSucceeds(as('tutor1').doc('classes/c1/members/bob').update({ status: 'approved', decidedAt: NOW() }));
});

test('joining a full class is refused', async () => {
  await assertFails(as('alice').doc('classes/full/members/alice').set({ uid: 'alice', name: 'Amina Haddad', role: 'student', childName: '', status: 'pending', requestedAt: NOW(), classId: 'full', classTitle: 'Physique Bac', tutorId: 'tutor1', tutorName: 'Karim Benali' }));
});

test('comments are refused when the tutor turned them off', async () => {
  const c = { authorId: 'alice', authorName: 'Amina Haddad', text: 'Merci', createdAt: NOW() };
  await assertFails(as('alice').collection('classes/c1/posts/p1/comments').add(c));
  await assertSucceeds(as('alice').collection('classes/c1/posts/p2/comments').add(c));
});

test('only approved students of the tutor can review', async () => {
  const r = { authorId: 'bob', authorName: 'Yacine Messaoud', rating: 5, text: 'Top', classId: 'c1', createdAt: NOW() };
  await assertFails(as('bob').doc('tutors/tutor1/reviews/bob').set(r));
  await assertSucceeds(as('alice').doc('tutors/tutor1/reviews/alice').set({ ...r, authorId: 'alice', authorName: 'Amina Haddad' }));
});

test('nobody can write rating fields on a tutor profile', async () => {
  await assertFails(as('tutor1').doc('tutors/tutor1').update({ ratingAvg: 5 }));
});
