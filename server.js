const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const multer = require('multer');
const bcrypt = require('bcrypt');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

const app = express();
app.use(cors(), express.json());
app.use('/uploads', express.static('uploads'));

mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log('MongoDB connected'))
  .catch(err => console.log(err));

const workerSchema = new mongoose.Schema({
  name: String,
  phone: String,
  password: String,
  address: String,
  category: String,
  isAvailable: { type: Boolean, default: false }, // NEW: Worker availability status
  location: { // NEW: GeoJSON Point for location
    type: {
      type: String,
      enum: ['Point'],
    },
    coordinates: {
      type: [Number], // [longitude, latitude]
    }
  },
  posts: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Post' }]
});

// NEW: Index for geospatial queries - CRITICAL for proximity search
workerSchema.index({ location: '2dsphere' });

const Worker = mongoose.model('Worker', workerSchema);

const postSchema = new mongoose.Schema({
  workerId: String,
  text: String,
  image: String,
  createdAt: { type: Date, default: Date.now }
});
const Post = mongoose.model('Post', postSchema);

const upload = multer({ dest: 'uploads/' });

app.post('/register', async (req, res) => {
  try {
    // MODIFIED: Added latitude and longitude
    const { name, phone, password, category, address, latitude, longitude } = req.body; 
    if (await Worker.findOne({ phone })) return res.status(400).json({ success: false, message: "Phone number already registered" });

    if (latitude === undefined || longitude === undefined) {
      return res.status(400).json({ success: false, message: "Location data (latitude and longitude) is required for registration." });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const newWorker = new Worker({
      name,
      phone,
      password: hashedPassword,
      category: category.toLowerCase(),
      address,
      location: { // NEW: Save location
        type: 'Point',
        coordinates: [longitude, latitude] // Note: GeoJSON uses [longitude, latitude]
      },
      isAvailable: false, // Default to not available upon registration
    });

    await newWorker.save();
    res.json({ success: true, message: "Registration successful!" });
  } catch (err) {
    console.log(err);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

app.post('/login', async (req, res) => {
  try {
    const { phone, password } = req.body;
    const worker = await Worker.findOne({ phone });

    if (worker && await bcrypt.compare(password, worker.password)) {
      // MODIFIED: Fetch and return full worker details including availability and location
      const workerDetails = await Worker.findById(worker._id).select('-password');
      return res.json({ success: true, message: "Login successful", worker: workerDetails });
    } else {
      return res.status(401).json({ success: false, message: "Invalid phone or password" });
    }
  } catch (err) {
    console.log(err);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

// NEW ROUTE: Update Worker Availability Status
app.post('/worker/availability', async (req, res) => {
  try {
    const { workerId, isAvailable } = req.body;
    if (!workerId || typeof isAvailable !== 'boolean') {
      return res.status(400).json({ success: false, message: "Invalid input" });
    }

    const worker = await Worker.findByIdAndUpdate(
      workerId,
      { isAvailable: isAvailable },
      { new: true, select: '-password' } // Return the updated document
    );

    if (!worker) {
      return res.status(404).json({ success: false, message: "Worker not found" });
    }

    res.json({ success: true, message: "Availability updated successfully", worker });
  } catch (err) {
    console.log(err);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

// NEW ROUTE: Find workers by Category, Availability, and Location (Proximity Search)
// Query parameters: category, latitude, longitude, radius (in km)
app.get('/workers/search', async (req, res) => {
  try {
    const { category, latitude, longitude, radius } = req.query;

    if (!category || !latitude || !longitude || !radius) {
      return res.status(400).json({ success: false, message: "Missing search parameters (category, location, or radius)" });
    }

    const maxDistanceInMeters = parseFloat(radius) * 1000; // Radius from KM to Meters

    const workers = await Worker.find({
      category: category.toLowerCase(), // Filter by category
      isAvailable: true, // Filter by availability status
      location: {
        $near: {
          $geometry: {
            type: "Point",
            coordinates: [parseFloat(longitude), parseFloat(latitude)] // GeoJSON uses [longitude, latitude]
          },
          $maxDistance: maxDistanceInMeters
        }
      }
    }).select('-password').populate('posts');

    if (!workers.length) {
      return res.status(404).json({ success: false, message: "No available workers found in this category and radius." });
    }

    res.json({ success: true, workers });

  } catch (err) {
    console.log(err);
    res.status(500).json({ success: false, message: "Server error during location search" });
  }
});

app.post('/upload-post', upload.single('image'), async (req, res) => {
// ... (existing post upload logic)
  try {
    const { workerId, text } = req.body;
    const image = req.file ? `uploads/${req.file.filename}` : null;
    const newPost = new Post({ workerId, text, image });
    await newPost.save();

    await Worker.findByIdAndUpdate(workerId, { $push: { posts: newPost._id } });

    res.json({ success: true, message: "Post uploaded successfully" });
  } catch (err) {
    console.log(err);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

app.get('/get-posts/:workerId', async (req, res) => {
  try {
    const posts = await Post.find({ workerId: req.params.workerId }).sort({ createdAt: -1 });
    res.json({ success: true, posts });
  } catch (err) {
    console.log(err);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

// The old simple category search route is removed/replaced by '/workers/search'
/*
app.get('/workers/category/:category', async (req, res) => {
  try {
    const workers = await Worker.find({ category: req.params.category }).select('-password').populate('posts');
    if (!workers.length) return res.status(404).json({ success: false, message: "No workers found" });
    res.json({ success: true, workers });
  } catch (err) {
    console.log(err);
    res.status(500).json({ success: false, message: "Server error" });
  }
});
*/

app.delete('/delete-post/:postId/:workerId', async (req, res) => {
  try {
    const { postId, workerId } = req.params;
    const post = await Post.findByIdAndDelete(postId);
    if (!post) return res.status(404).json({ success: false, message: "Post not found" });
    if (post.image) fs.unlink(path.join(__dirname, post.image), (err) => console.log(err));
    await Worker.findByIdAndUpdate(workerId, { $pull: { posts: postId } });
    res.json({ success: true, message: "Post deleted" });
  } catch (err) {
    console.log(err);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
