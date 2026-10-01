require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./models/User');

async function test() {
  await mongoose.connect(process.env.MONGO_URI);
  
  // Test CS Student
  const csStudent = await User.findOne({ email: 'ansilasherin123@gmail.com' });
  console.log(`\n=== Testing for CS Student: ${csStudent.name} (${csStudent.department}) ===`);
  const csContacts = await User.find({
    _id: { $ne: csStudent._id },
    department: csStudent.department
  });
  const csTeachers = csContacts.filter(c => c.role === 'teacher' || c.role === 'admin');
  const csStudents = csContacts.filter(c => c.role === 'student');
  console.log(`CS Teachers (${csTeachers.length}):`, csTeachers.map(t => `${t.name} [${t.role}]`));
  console.log(`CS Classmates (${csStudents.length}):`, csStudents.map(s => `${s.name} [${s.role}]`));

  // Test AI&DS Student
  const aidsStudent = await User.findOne({ email: 'ansila@gmail.com' });
  console.log(`\n=== Testing for AI&DS Student: ${aidsStudent.name} (${aidsStudent.department}) ===`);
  const aidsContacts = await User.find({
    _id: { $ne: aidsStudent._id },
    department: aidsStudent.department
  });
  const aidsTeachers = aidsContacts.filter(c => c.role === 'teacher' || c.role === 'admin');
  const aidsStudents = aidsContacts.filter(c => c.role === 'student');
  console.log(`AI&DS Teachers (${aidsTeachers.length}):`, aidsTeachers.map(t => `${t.name} [${t.role}]`));
  console.log(`AI&DS Classmates (${aidsStudents.length}):`, aidsStudents.map(s => `${s.name} [${s.role}]`));

  process.exit(0);
}

test().catch(e => {
  console.error(e);
  process.exit(1);
});
