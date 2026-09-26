const dns = require('dns');
const mongoose = require('mongoose');

// Configure reliable DNS servers to prevent querySrv ETIMEOUT issues on Windows/ISP DNS
try {
    dns.setServers(['8.8.8.8', '8.8.4.4', '1.1.1.1']);
} catch (err) {
    console.warn('⚠️ Could not set custom DNS servers:', err.message);
}

const connectDB = async () => {
    try {
        const conn = await mongoose.connect(process.env.MONGO_URI);
        console.log(`=========================================`);
        console.log(`✅ MongoDB Connected Successfully!`);
        console.log(`🌐 Host: ${conn.connection.host}`);
        console.log(`📦 Database: ${conn.connection.name}`);
        console.log(`=========================================`);
    } catch (error) {
        console.error(`❌ MongoDB Connection Failed: ${error.message}`);
        process.exit(1);
    }
};

module.exports = connectDB;

