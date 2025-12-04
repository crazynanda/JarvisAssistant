# Deploying J.A.R.V.I.S Server to Google Cloud Run

This guide details how to build and deploy the J.A.R.V.I.S backend container to Google Cloud Run.

## Prerequisites

1.  **Google Cloud SDK**: Ensure `gcloud` CLI is installed and initialized.
2.  **Project**: You need an active Google Cloud Project.

## Deployment Steps

### 1. Authenticate and Configure

Login to your Google Cloud account and set your project ID:

```bash
gcloud auth login
gcloud config set project [YOUR_PROJECT_ID]
```

### 2. Build the Container

Submit the build to Google Cloud Build. This creates a container image stored in Google Container Registry (GCR).

```bash
gcloud builds submit --tag gcr.io/[YOUR_PROJECT_ID]/jarvis-server
```

*Replace `[YOUR_PROJECT_ID]` with your actual project ID.*

### 3. Deploy to Cloud Run

Deploy the container to Cloud Run. This command sets up the service, exposes port 8000, and configures environment variables.

```bash
gcloud run deploy jarvis-server \
  --image gcr.io/[YOUR_PROJECT_ID]/jarvis-server \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 8000 \
  --set-env-vars OPENAI_API_KEY=[YOUR_OPENAI_KEY]
```

*   **`--allow-unauthenticated`**: Makes the service publicly accessible (required for the Flutter app to reach it without IAM auth).
*   **`--set-env-vars`**: Pass your `OPENAI_API_KEY` here. You can also add `OPENWEATHER_API_KEY` if needed.

## Verification

Once deployed, Cloud Run will provide a Service URL.

**Example Endpoint URL:**
`https://jarvis-server-[hash]-uc.a.run.app`

**Health Check:**
Visit `https://jarvis-server-[hash]-uc.a.run.app/health` to verify the server is running.

## Updating the App

To deploy changes, simply run the **Build** and **Deploy** commands again.
