# Backend Environment Configuration

## `.env` File Structure

Create a `.env` file in the `backend` folder with the following variables:

```env
# MongoDB Configuration
MONGODB_URI=your_mongodb_connection_string

# JWT Configuration
JWT_SECRET=your_jwt_secret_key

# Server Configuration
PORT=3000

# Cloudinary Configuration
CLOUDINARY_CLOUD_NAME=your_cloudinary_cloud_name
CLOUDINARY_API_KEY=your_cloudinary_api_key
CLOUDINARY_API_SECRET=your_cloudinary_api_secret
```

## Environment Variables Description

### MongoDB Configuration
- **MONGODB_URI**: MongoDB connection string
  - Example: `mongodb+srv://username:password@cluster.mongodb.net/database_name`
  - Get this from MongoDB Atlas or your MongoDB instance

### JWT Configuration
- **JWT_SECRET**: Secret key for signing JWT tokens
  - Use a strong, random string
  - **Important**: Change this in production for security

### Server Configuration
- **PORT**: Port number for the server to run on
  - Default: `3000`
  - Change if port 3000 is already in use

### Cloudinary Configuration
- **CLOUDINARY_CLOUD_NAME**: Your Cloudinary cloud name
  - Used for image upload and storage
  - Get this from [Cloudinary Console](https://cloudinary.com/console)

- **CLOUDINARY_API_KEY**: Your Cloudinary API key

- **CLOUDINARY_API_SECRET**: Your Cloudinary API secret

## Authentication Flow

This backend uses **mock Aadhaar verification** for authentication:

1. User enters 12-digit Aadhaar number
2. Backend generates a mock request ID and simulates sending OTP
3. User enters OTP (mock OTP is `123456`)
4. If Aadhaar exists in database → user is logged in
5. If Aadhaar is new → user proceeds to registration

**Note**: This is a mock implementation for demonstration purposes. In production, integrate with UIDAI's Aadhaar authentication API.
