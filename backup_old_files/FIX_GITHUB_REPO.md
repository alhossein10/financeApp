# Fix Your GitHub Repository for Render

## Problem

Your repository has `dockerfile.txt` but Render needs `Dockerfile` (no extension).

## Solution

### Step 1: Delete the Wrong File

In your `pocketbase-backend` repository on GitHub:
1. Go to https://github.com/alhossein10/pocketbase-backend
2. Click on `dockerfile.txt`
3. Click the trash icon to delete it
4. Commit the deletion

### Step 2: Add the Correct Files

I've created the correct files in the `pocketbase-backend-files` folder in your current project.

You need to copy these files to your `pocketbase-backend` repository:

**Option A: Using GitHub Web Interface**

1. Go to https://github.com/alhossein10/pocketbase-backend
2. Click "Add file" → "Create new file"
3. Name it `Dockerfile` (exactly, no extension)
4. Copy the content from `pocketbase-backend-files/Dockerfile`
5. Commit the file
6. Repeat for `.gitignore` and `README.md`

**Option B: Using Git Command Line**

```bash
# Navigate to your pocketbase-backend repository
cd /path/to/pocketbase-backend

# Delete the wrong file
git rm dockerfile.txt

# Copy the correct files from this project
cp /path/to/your-flutter-project/pocketbase-backend-files/Dockerfile .
cp /path/to/your-flutter-project/pocketbase-backend-files/.gitignore .
cp /path/to/your-flutter-project/pocketbase-backend-files/README.md .

# Add and commit
git add Dockerfile .gitignore README.md
git commit -m "Add correct Dockerfile for Render deployment"
git push origin main
```

### Step 3: Verify on GitHub

Your repository should now look like this:

```
pocketbase-backend/
├── Dockerfile       ← Correct name, no extension
├── .gitignore
└── README.md
```

### Step 4: Redeploy on Render

1. Go to your Render dashboard
2. Your service should automatically detect the new commit and start deploying
3. If not, click "Manual Deploy" → "Deploy latest commit"
4. Wait for the build to complete (should succeed this time!)

### Step 5: Add Persistent Disk

After the deployment succeeds:
1. Go to your service in Render
2. Click "Settings" in the left sidebar
3. Scroll to "Disks" section
4. Click "Add Disk"
5. Configure:
   - Name: `pb_data`
   - Mount Path: `/pb/pb_data`
   - Size: `1 GB`
6. Click "Save Changes"
7. Service will redeploy with the disk attached

## Files Content

### Dockerfile
```dockerfile
FROM alpine:latest

ARG PB_VERSION=0.22.0

RUN apk add --no-cache \
    unzip \
    ca-certificates

# Download and install PocketBase
ADD https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_amd64.zip /tmp/pb.zip
RUN unzip /tmp/pb.zip -d /pb/ && \
    chmod +x /pb/pocketbase

# Create data directory
RUN mkdir -p /pb/pb_data

EXPOSE 8080

# Start PocketBase
CMD ["/pb/pocketbase", "serve", "--http=0.0.0.0:8080", "--dir=/pb/pb_data"]
```

### .gitignore
```
pb_data/
*.db
*.db-shm
*.db-wal
```

## Important Notes

1. **Filename is critical**: Must be `Dockerfile` not `dockerfile.txt` or `Dockerfile.txt`
2. **Location is critical**: Must be in the root of the repository
3. **Case sensitive**: `Dockerfile` with capital D
4. **No extension**: Just `Dockerfile`, not `Dockerfile.txt`

## After Successful Deployment

Once deployed, you can:
1. Access PocketBase admin UI at: `https://your-service-name.onrender.com/_/`
2. Create your admin account
3. Set up collections (expenses, invoice_files)
4. Configure collection rules
5. Update your Flutter app with the production URL

## Need Help?

If you're still having issues:
- Make sure the Dockerfile is in the root
- Check the filename is exactly `Dockerfile`
- Verify the content matches the template above
- Try manually triggering a deploy in Render
