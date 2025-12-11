const cloudinary = require('cloudinary').v2;
const { Readable } = require('stream');

// Configure Cloudinary lazily - only when credentials are available
let cloudinaryConfigured = false;

const configureCloudinary = () => {
  // Check if credentials are configured
  if (!process.env.CLOUDINARY_CLOUD_NAME || 
      !process.env.CLOUDINARY_API_KEY || 
      !process.env.CLOUDINARY_API_SECRET) {
    throw new Error('Cloudinary credentials not configured. Please set CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, and CLOUDINARY_API_SECRET in your .env file');
  }

  // Only configure if not already configured or if credentials changed
  if (!cloudinaryConfigured) {
    cloudinary.config({
      cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
      api_key: process.env.CLOUDINARY_API_KEY,
      api_secret: process.env.CLOUDINARY_API_SECRET,
    });
    cloudinaryConfigured = true;
  }
};

/**
 * Upload image to Cloudinary
 * @param {Object} file - Multer file object
 * @returns {Promise<string>} - Cloudinary URL
 */
const uploadImage = async (file) => {
  try {
    if (!file) {
      throw new Error('No file provided');
    }

    // Configure Cloudinary before use
    configureCloudinary();

    return new Promise((resolve, reject) => {
      // Create a readable stream from the buffer
      const stream = cloudinary.uploader.upload_stream(
        {
          folder: 'antardrishti/profiles',
          resource_type: 'image',
          transformation: [
            { width: 500, height: 500, crop: 'fill', gravity: 'face' },
            { quality: 'auto' },
            { format: 'jpg' }
          ]
        },
        (error, result) => {
          if (error) {
            console.error('Cloudinary upload error:', error);
            reject(new Error('Failed to upload image to Cloudinary'));
          } else {
            resolve(result.secure_url);
          }
        }
      );

      // Write buffer to stream
      stream.end(file.buffer);
    });
  } catch (error) {
    console.error('Cloudinary upload error:', error);
    throw new Error(error.message || 'Failed to upload image');
  }
};

module.exports = {
  uploadImage,
};

