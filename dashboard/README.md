# FindX Analytics Dashboard

A real-time analytics dashboard for the FindX Lost & Found platform.

## 🚀 Deploy to Vercel

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https://github.com/YOUR_USERNAME/findx-dashboard)

### One-Click Deploy
1. Click the button above
2. Connect your GitHub account
3. Add your Firebase environment variables
4. Deploy!

## 🔧 Environment Variables

Required variables for Vercel deployment:

| Variable | Description |
|----------|-------------|
| `NEXT_PUBLIC_FIREBASE_API_KEY` | Firebase API Key |
| `NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN` | Firebase Auth Domain |
| `NEXT_PUBLIC_FIREBASE_PROJECT_ID` | Firebase Project ID |
| `NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET` | Firebase Storage Bucket |
| `NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID` | Firebase Sender ID |
| `NEXT_PUBLIC_FIREBASE_APP_ID` | Firebase App ID |

## 📊 Features

- **Real-time Stats**: Total items, lost/found counts, returned items
- **User Analytics**: Total users, daily active users
- **Charts**: 
  - 📈 Daily reports (Line chart)
  - 🍩 Items by category (Doughnut chart)
  - 📊 Status overview (Bar chart)
- **Items Management**: View all items with filtering
- **Dark Mode**: Automatic theme detection

## 🛠️ Local Development

```bash
# Install dependencies
npm install

# Copy environment variables
cp .env.example .env.local
# Edit .env.local with your Firebase config

# Run development server
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

## 📁 Project Structure

```
dashboard/
├── app/
│   ├── page.tsx          # Main dashboard
│   ├── items/page.tsx    # Items list
│   ├── layout.tsx        # App layout with sidebar
│   └── globals.css       # Global styles
├── lib/
│   └── firebase.ts       # Firebase config
└── public/               # Static assets
```

## 🎨 Tech Stack

- **Next.js 14** - React framework
- **Tailwind CSS** - Styling
- **Chart.js** - Data visualization
- **Firebase** - Backend & Database

## 📝 License

MIT License - FindX Team
