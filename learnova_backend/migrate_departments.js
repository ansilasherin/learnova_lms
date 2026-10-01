require('dotenv').config();
const mongoose = require('mongoose');

async function migrate() {
  await mongoose.connect(process.env.MONGO_URI);
  const db = mongoose.connection.db;

  console.log('Updating seed users with department fields...');
  
  // Update Prof. Rajesh Mehta
  await db.collection('users').updateOne(
    { email: 'prof.mehta@gmail.com' },
    { $set: { department: 'Computer Science & Engineering', designation: 'Professor & HOD', semester: 'Semester 1', batch: '2024 - 2028' } }
  );

  // Update Prof. Anita Iyer
  await db.collection('users').updateOne(
    { email: 'prof.iyer@gmail.com' },
    { $set: { department: 'Computer Science & Engineering', designation: 'Assistant Professor', semester: 'Semester 1', batch: '2024 - 2028' } }
  );

  // Update Ananya Sharma
  await db.collection('users').updateOne(
    { email: 'ananya.student@gmail.com' },
    { $set: { department: 'Computer Science & Engineering', semester: 'Semester 1', batch: '2024 - 2028' } }
  );

  // Update Learnova Administrator
  await db.collection('users').updateOne(
    { email: 'admin@learnova.com' },
    { $set: { department: 'Computer Science & Engineering', designation: 'Dean & LMS Admin' } }
  );

  // Update Ansila Sherin NP
  await db.collection('users').updateOne(
    { email: 'ansilasherin123@gmail.com' },
    { $set: { department: 'Computer Science & Engineering', semester: 'Semester 1', batch: '2024 - 2028' } }
  );

  // Update any other users with missing department to default
  await db.collection('users').updateMany(
    { department: { $exists: false } },
    { $set: { department: 'Computer Science & Engineering' } }
  );

  console.log('Migration complete. Inspecting all users:');
  const all = await db.collection('users').find({}).toArray();
  all.forEach(u => console.log(` - [${u.role}] ${u.name} | Dept: "${u.department}" | Email: ${u.email}`));

  process.exit(0);
}

migrate().catch(e => {
  console.error(e);
  process.exit(1);
});
