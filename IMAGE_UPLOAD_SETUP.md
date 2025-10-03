# Image Upload Setup Guide

## Overview
The app has been updated to support multiple image selection from the device's gallery or camera instead of URL input for product images.

## Changes Made

### 1. Dependencies Added
- `image_picker: ^1.0.7` - For selecting images from gallery/camera
- `image_picker_for_web: ^2.1.4` - Web support for image picker
- `path_provider: ^2.1.2` - For file system access
- `mime: ^1.0.5` - For MIME type detection
- `http_parser: ^4.0.2` - For HTTP multipart requests

### 2. Permissions Added
**Android (android/app/src/main/AndroidManifest.xml):**
- `android.permission.CAMERA`
- `android.permission.READ_EXTERNAL_STORAGE`
- `android.permission.WRITE_EXTERNAL_STORAGE`
- `android.permission.READ_MEDIA_IMAGES`

**iOS (ios/Runner/Info.plist):**
- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`

### 3. Backend Changes
- Added `multer` and `cloudinary` dependencies
- Created `/backend/routes/upload.js` for handling image uploads
- Added static file serving for uploaded images
- Updated server.js to include upload routes

### 4. Frontend Changes
- Created `lib/services/image_service.dart` for image handling
- Updated add product form in `lib/screens/home_screen.dart`
- Replaced URL input with image picker interface
- Added support for multiple image selection (up to 5 images)
- Added image preview and removal functionality

## Setup Instructions

### 1. Install Dependencies
```bash
# Install Flutter dependencies
flutter pub get

# Install backend dependencies
cd backend
npm install
```

### 2. Configure Cloudinary
Create a `.env` file in the `backend` directory with your Cloudinary credentials:

```env
# Database
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/prerna_grocery?retryWrites=true&w=majority

# JWT
JWT_SECRET=your_super_secret_jwt_key_here_make_it_long_and_random

# Server
PORT=5000
NODE_ENV=development

# Cloudinary Configuration
CLOUDINARY_CLOUD_NAME=your_cloudinary_cloud_name
CLOUDINARY_API_KEY=your_cloudinary_api_key
CLOUDINARY_API_SECRET=your_cloudinary_api_secret

# CORS
FRONTEND_URL=http://localhost:3000
```

### 3. Start the Backend Server
```bash
cd backend
npm run dev
# or
npm start
```

### 4. Run the Flutter App
```bash
flutter run
```

## Testing the Image Upload Feature

1. **Navigate to Add Product**: Go to the home screen and tap the "Add Product" button (if you're a seller)

2. **Select Images**: 
   - Tap "Gallery" to select multiple images from your photo library
   - Tap "Camera" to take a new photo
   - You can select up to 5 images total

3. **Preview Images**: 
   - Selected images will appear in a horizontal scrollable list
   - Tap the red X button to remove individual images

4. **Submit Product**: 
   - Fill in all required fields
   - Tap "Add Product" to upload images and create the product
   - You'll see "Uploading Images..." progress indicator

## Features

- **Multiple Image Selection**: Choose up to 5 images per product
- **Gallery & Camera Support**: Select from existing photos or take new ones
- **Image Preview**: See selected images before uploading
- **Image Removal**: Remove individual images before submission
- **Progress Indicators**: Visual feedback during upload process
- **Error Handling**: Proper error messages for failed uploads
- **Validation**: Ensures at least one image is selected
- **Multiple Image Display**: Product cards now show all images with swipeable carousel
- **Image Indicators**: Dots and image count indicators for multiple images

## Backend API Endpoints

- `POST /api/upload/image` - Upload single image
- `POST /api/upload/images` - Upload multiple images
- `DELETE /api/upload/image/:filename` - Delete uploaded image

## File Storage

Images are uploaded to **Cloudinary** cloud storage with the following benefits:
- **CDN Delivery**: Fast global image delivery
- **Automatic Optimization**: Images are automatically optimized for web (WebP, AVIF)
- **Responsive Images**: Automatic resizing and format conversion
- **Folder Organization**: Images stored in `prerna-grocery/products/` folder
- **Transformations**: Images are resized to max 1920x1080 with quality optimization

## Troubleshooting

1. **Permission Issues**: Make sure camera and storage permissions are granted
2. **Upload Failures**: 
   - Check backend server is running and accessible
   - Verify Cloudinary credentials in `.env` file
   - Check Cloudinary dashboard for upload limits
   - **401 Unauthorized**: Make sure you're logged in as a seller/vendor
   - Check authentication token is valid
3. **Image Quality**: Images are automatically optimized by Cloudinary with quality auto and format conversion
4. **File Size**: Maximum file size is 5MB per image
5. **Cloudinary Issues**: 
   - Verify your Cloudinary account is active
   - Check API key permissions
   - Ensure sufficient storage quota
6. **Web Platform Issues**:
   - If running on Flutter Web, image previews use `Image.network` instead of `Image.file`
   - Make sure you're using the latest version of `image_picker_for_web`
   - Web platform automatically handles image format compatibility

## Future Enhancements

- Image editing capabilities (crop, rotate, filters)
- Batch upload progress tracking
- Image format validation
- Advanced Cloudinary transformations
- Image watermarking
- Automatic background removal
