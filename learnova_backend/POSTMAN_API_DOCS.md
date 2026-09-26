# 📚 Learnova LMS Backend - Complete Postman API Documentation

Base URL: `http://localhost:5000`

---

## 📑 Table of Contents
1. [Authentication APIs](#1-authentication-apis)
   - [Register User (Student / Teacher / Admin)](#11-register-user)
   - [Login User](#12-login-user)
   - [Get Logged-in User Profile (Me)](#13-get-me)
2. [User Profile APIs](#2-user-profile-apis)
   - [View Profile](#21-view-profile)
   - [Update Profile](#22-update-profile)
3. [Course Management APIs](#3-course-management-apis)
   - [Browse All Courses (Public)](#31-browse-all-courses-public)
   - [Get Single Course Details (Public)](#32-get-single-course-details-public)
   - [Create Course (Teacher/Admin)](#33-create-course-teacher--admin)
   - [Update Course (Teacher/Admin)](#34-update-course-teacher--admin)
   - [Delete Course (Teacher/Admin)](#35-delete-course-teacher--admin)
   - [Add Lesson to Course (Teacher/Admin)](#36-add-lesson-to-course-teacher--admin)
4. [Enrollment & Progress APIs](#4-enrollment--progress-apis)
   - [Enroll in a Course (Student)](#41-enroll-in-a-course-student)
   - [View My Enrolled Courses (Student)](#42-view-my-enrolled-courses-student)
   - [Get Course Progress (Student)](#43-get-course-progress-student)
   - [Mark Lesson as Completed (Student)](#44-mark-lesson-as-completed-student)
5. [Role-Based Access Control (RBAC) Test APIs](#5-role-test-apis)
   - [Student Test Route](#51-student-test-route)
   - [Teacher Test Route](#52-teacher-test-route)
   - [Admin Test Route](#53-admin-test-route)

---

## 🔑 Common Headers

| Header Key | Header Value | When to use |
| :--- | :--- | :--- |
| `Content-Type` | `application/json` | Ella POST & PUT requests-inum |
| `Authorization` | `Bearer <your_jwt_token>` | Ella Protected (Private) APIs-inum |

---

# 1. Authentication APIs

### 1.1. Register User
* **Method:** `POST`
* **URL:** `http://localhost:5000/api/auth/register`
* **Headers:**
  * `Content-Type: application/json`
* **Request Body (JSON):**
```json
{
  "name": "Ananya Sharma",
  "email": "ananya.student@gmail.com",
  "phone": "+91 9876543210",
  "password": "Password123",
  "role": "student"
}
```
*(Note: Roles allow cheyyunnath: `"student"`, `"teacher"`, `"admin"`)*

* **Expected Response (`201 Created`):**
```json
{
  "success": true,
  "message": "User registered successfully! 🎉",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "67dc5971234567890abcdef",
    "name": "Ananya Sharma",
    "email": "ananya.student@gmail.com",
    "phone": "+91 9876543210",
    "role": "student",
    "studentId": null,
    "profileImage": "https://api.dicebear.com/7.x/bottts/svg?seed=Learnova",
    "createdAt": "2026-09-18T10:17:26.000Z"
  }
}
```

---

### 1.2. Login User
* **Method:** `POST`
* **URL:** `http://localhost:5000/api/auth/login`
* **Headers:**
  * `Content-Type: application/json`
* **Request Body (JSON):**
```json
{
  "email": "ananya.student@gmail.com",
  "password": "Password123"
}
```
* **Expected Response (`200 OK`):**
```json
{
  "success": true,
  "message": "Logged in successfully! 🚀",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "67dc5971234567890abcdef",
    "name": "Ananya Sharma",
    "email": "ananya.student@gmail.com",
    "role": "student"
  }
}
```

---

### 1.3. Get Me (Protected Profile)
* **Method:** `GET`
* **URL:** `http://localhost:5000/api/auth/me`
* **Headers:**
  * `Authorization: Bearer <your_jwt_token>`
* **Expected Response (`200 OK`):**
```json
{
  "success": true,
  "message": "User profile fetched successfully! 👤",
  "user": {
    "_id": "67dc5971234567890abcdef",
    "name": "Ananya Sharma",
    "email": "ananya.student@gmail.com",
    "role": "student"
  }
}
```

---

# 2. User Profile APIs

### 2.1. View Profile
* **Method:** `GET`
* **URL:** `http://localhost:5000/api/users/profile`
* **Headers:**
  * `Authorization: Bearer <your_jwt_token>`
* **Expected Response (`200 OK`):**
```json
{
  "success": true,
  "message": "Profile fetched successfully! 👤",
  "user": {
    "_id": "67dc5971234567890abcdef",
    "name": "Ananya Sharma",
    "email": "ananya.student@gmail.com",
    "phone": "+91 9876543210",
    "role": "student",
    "profileImage": "https://api.dicebear.com/7.x/bottts/svg?seed=Learnova"
  }
}
```

---

### 2.2. Update Profile
* **Method:** `PUT`
* **URL:** `http://localhost:5000/api/users/profile`
* **Headers:**
  * `Authorization: Bearer <your_jwt_token>`
  * `Content-Type: application/json`
* **Request Body (JSON):**
```json
{
  "name": "Ananya S. Kumar",
  "phone": "+91 9447001122",
  "profileImage": "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150"
}
```
* **Expected Response (`200 OK`):**
```json
{
  "success": true,
  "message": "Profile updated successfully! 🎉",
  "user": {
    "id": "67dc5971234567890abcdef",
    "name": "Ananya S. Kumar",
    "email": "ananya.student@gmail.com",
    "phone": "+91 9447001122",
    "role": "student",
    "profileImage": "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150"
  }
}
```

---

# 3. Course Management APIs

### 3.1. Browse All Courses (Public)
* **Method:** `GET`
* **URL:** `http://localhost:5000/api/courses`
* *(Optional Filter Params: `http://localhost:5000/api/courses?category=Mobile&search=Flutter&level=Beginner`)*
* **Headers:** None needed
* **Expected Response (`200 OK`):**
```json
{
  "success": true,
  "count": 1,
  "message": "Courses fetched successfully! 📚",
  "courses": [
    {
      "_id": "67dc60001234567890abcdef",
      "title": "Flutter & Node.js LMS Masterclass",
      "description": "Full-stack course from scratch",
      "category": "Mobile Development",
      "price": 1999,
      "level": "Beginner",
      "instructor": {
        "name": "Teacher Priya",
        "email": "priya.teacher@gmail.com"
      },
      "lessons": []
    }
  ]
}
```

---

### 3.2. Get Single Course Details (Public)
* **Method:** `GET`
* **URL:** `http://localhost:5000/api/courses/<course_id>`
* **Headers:** None needed
* **Expected Response (`200 OK`):**
```json
{
  "success": true,
  "course": {
    "_id": "67dc60001234567890abcdef",
    "title": "Flutter & Node.js LMS Masterclass",
    "lessons": []
  }
}
```

---

### 3.3. Create Course (Teacher / Admin)
* **Method:** `POST`
* **URL:** `http://localhost:5000/api/courses`
* **Headers:**
  * `Authorization: Bearer <teacher_or_admin_jwt_token>`
  * `Content-Type: application/json`
* **Request Body (JSON):**
```json
{
  "title": "Complete Flutter & Node.js LMS Masterclass 2026",
  "description": "Learn backend APIs, database management, and mobile frontend.",
  "category": "Mobile Development",
  "price": 2499,
  "level": "Beginner",
  "thumbnail": "https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=600"
}
```
* **Expected Response (`201 Created`):**
```json
{
  "success": true,
  "message": "Course created successfully! 🎉",
  "course": {
    "_id": "67dc60001234567890abcdef",
    "title": "Complete Flutter & Node.js LMS Masterclass 2026",
    "instructor": "67dc5971234567890abcdef",
    "price": 2499
  }
}
```

---

### 3.4. Update Course (Teacher / Admin)
* **Method:** `PUT`
* **URL:** `http://localhost:5000/api/courses/<course_id>`
* **Headers:**
  * `Authorization: Bearer <teacher_or_admin_jwt_token>`
  * `Content-Type: application/json`
* **Request Body (JSON):**
```json
{
  "price": 1999,
  "level": "All Levels"
}
```
* **Expected Response (`200 OK`):**
```json
{
  "success": true,
  "message": "Course updated successfully! ✅",
  "course": {
    "_id": "67dc60001234567890abcdef",
    "price": 1999,
    "level": "All Levels"
  }
}
```

---

### 3.5. Delete Course (Teacher / Admin)
* **Method:** `DELETE`
* **URL:** `http://localhost:5000/api/courses/<course_id>`
* **Headers:**
  * `Authorization: Bearer <teacher_or_admin_jwt_token>`
* **Expected Response (`200 OK`):**
```json
{
  "success": true,
  "message": "Course deleted successfully! 🗑️"
}
```

---
// api get cheythit error aanu
### 3.6. Add Lesson to Course (Teacher / Admin)
* **Method:** `POST`
* **URL:** `http://localhost:5000/api/courses/<course_id>/lessons`
* **Headers:**
  * `Authorization: Bearer <teacher_or_admin_jwt_token>`
  * `Content-Type: application/json`
* **Request Body (JSON):**
```json
{
  "title": "01 - Introduction to Node.js & Express Architecture",
  "description": "Overview of backend API workflow and architecture.",
  "videoUrl": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
  "duration": "15 mins",
  "isFreePreview": true
}
```
* **Expected Response (`201 Created`):**
```json
{
  "success": true,
  "message": "Lesson added successfully! 🎬",
  "lessons": [
    {
      "_id": "67dc65001234567890abcdef",
      "title": "01 - Introduction to Node.js & Express Architecture",
      "videoUrl": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
      "duration": "15 mins",
      "isFreePreview": true
    }
  ]
}
```

---

# 4. Enrollment & Progress APIs

### 4.1. Enroll in a Course (Student)
* **Method:** `POST`
* **URL:** `http://localhost:5000/api/enrollments/<course_id>`
* **Headers:**
  * `Authorization: Bearer <student_jwt_token>`
* **Expected Response (`201 Created`):**
```json
{
  "success": true,
  "message": "Successfully enrolled in \"Complete Flutter & Node.js LMS Masterclass 2026\"! 🎓",
  "enrollment": {
    "_id": "67dc70001234567890abcdef",
    "student": "67dc5971234567890abcdef",
    "course": "67dc60001234567890abcdef",
    "completedLessons": [],
    "progressPercentage": 0,
    "isCompleted": false
  }
}
```

---

### 4.2. View My Enrolled Courses (Student)
* **Method:** `GET`
* **URL:** `http://localhost:5000/api/enrollments/my-courses`
* **Headers:**
  * `Authorization: Bearer <student_jwt_token>`
* **Expected Response (`200 OK`):**
```json
{
  "success": true,
  "count": 1,
  "message": "Enrolled courses fetched successfully! 📖",
  "enrollments": [
    {
      "_id": "67dc70001234567890abcdef",
      "progressPercentage": 0,
      "isCompleted": false,
      "course": {
        "_id": "67dc60001234567890abcdef",
        "title": "Complete Flutter & Node.js LMS Masterclass 2026",
        "thumbnail": "https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=600"
      }
    }
  ]
}
```

---
 
### 4.3. Get Course Progress (Student)
* **Method:** `GET`
* **URL:** `http://localhost:5000/api/enrollments/<course_id>/progress`
* **Headers:**
  * `Authorization: Bearer <student_jwt_token>`
* **Expected Response (`200 OK`):**
```json
{
  "success": true,
  "enrollment": {
    "_id": "67dc70001234567890abcdef",
    "progressPercentage": 50,
    "isCompleted": false,
    "completedLessons": ["67dc65001234567890abcdef"]
  }
}
```

---

### 4.4. Mark Lesson as Completed (Student)
* **Method:** `PUT`
* **URL:** `http://localhost:5000/api/enrollments/<course_id>/lessons/<lesson_id>/complete`
* **Headers:**
  * `Authorization: Bearer <student_jwt_token>`
* **Expected Response (`200 OK`):**
```json
{
  "success": true,
  "message": "Lesson progress updated successfully! ✅",
  "progressPercentage": 100,
  "isCompleted": true,
  "completedLessonsCount": 2,
  "totalLessonsCount": 2
}

```
---

# 5. Role Test APIs

### 5.1. Student Test Route
* **Method:** `GET`
* **URL:** `http://localhost:5000/api/test/student`
* **Headers:** `Authorization: Bearer <student_jwt_token>`
* **Response:** `200 OK` (Only for Student role, 403 for other roles)

### 5.2. Teacher Test Route
* **Method:** `GET`
* **URL:** `http://localhost:5000/api/test/teacher`
* **Headers:** `Authorization: Bearer <teacher_jwt_token>`
* **Response:** `200 OK` (Only for Teacher role, 403 for other roles)

### 5.3. Admin Test Route
* **Method:** `GET`
* **URL:** `http://localhost:5000/api/test/admin`
* **Headers:** `Authorization: Bearer <admin_jwt_token>`
* **Response:** `200 OK` (Only for Admin role, 403 for other roles)
