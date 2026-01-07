# 🔍 FINDX - AI-Powered Lost & Found Platform

<div align="center">

![Next.js](https://img.shields.io/badge/Next.js-14-black?style=for-the-badge&logo=next.js)
![TypeScript](https://img.shields.io/badge/TypeScript-5.0-blue?style=for-the-badge&logo=typescript)
![Firebase](https://img.shields.io/badge/Firebase-10.7-orange?style=for-the-badge&logo=firebase)
![Gemini AI](https://img.shields.io/badge/Gemini-AI-purple?style=for-the-badge&logo=google)
![TailwindCSS](https://img.shields.io/badge/Tailwind-3.4-38B2AC?style=for-the-badge&logo=tailwind-css)

**Reunite people with their lost belongings using the power of AI**

[Live Demo](findx-web.vercel.app) · [Report Bug](https://github.com/MUTHUKUMARAN-K-1/FINDX/issues) · [Request Feature](https://github.com/MUTHUKUMARAN-K-1/FINDX/issues)

</div>

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🤖 **AI Image Analysis** | Automatic item categorization and description using Google Gemini |
| 🎤 **Voice Input** | Hands-free reporting with speech recognition |
| 🗺️ **Location Matching** | GPS-based matching to find items near you |
| 🔔 **Smart Notifications** | Get alerted when potential matches are found |
| 🔒 **Secure Claims** | Verification questions to ensure rightful ownership |
| 🌙 **Dark Mode** | Beautiful UI with light/dark theme support |
| 📱 **Responsive** | Works seamlessly on desktop, tablet, and mobile |

---

## 🚀 Quick Start

### Prerequisites

- Node.js 18+ 
- npm or yarn
- Firebase account
- Google Gemini API key

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/MUTHUKUMARAN-K-1/FINDX.git
   cd FINDX
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Set up environment variables**
   
   Copy the example environment file:
   ```bash
   cp .env.example .env.local
   ```
   
   Fill in your credentials in `.env.local`:
   ```env
   # Firebase Configuration
   NEXT_PUBLIC_FIREBASE_API_KEY=your_api_key
   NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
   NEXT_PUBLIC_FIREBASE_PROJECT_ID=your_project_id
   NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=your_project.appspot.com
   NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=your_sender_id
   NEXT_PUBLIC_FIREBASE_APP_ID=your_app_id
   
   # Google Gemini AI
   NEXT_PUBLIC_GEMINI_API_KEY=your_gemini_api_key
   ```

4. **Run the development server**
   ```bash
   npm run dev
   ```

5. **Open your browser**
   
   Navigate to [http://localhost:3000](http://localhost:3000)

---

## 🛠️ Tech Stack

- **Framework**: [Next.js 14](https://nextjs.org/) with App Router
- **Language**: [TypeScript](https://www.typescriptlang.org/)
- **Styling**: [Tailwind CSS](https://tailwindcss.com/)
- **Authentication**: [Firebase Auth](https://firebase.google.com/docs/auth)
- **Database**: [Cloud Firestore](https://firebase.google.com/docs/firestore)
- **Storage**: [Firebase Storage](https://firebase.google.com/docs/storage)
- **AI**: [Google Gemini](https://ai.google.dev/)
- **Animations**: [Framer Motion](https://www.framer.com/motion/)
- **Icons**: [Lucide React](https://lucide.dev/)

---

## 📁 Project Structure

```
findx/
├── src/
│   ├── app/                 # Next.js App Router pages
│   │   ├── item/[id]/       # Item detail page
│   │   ├── matches/         # Matches page
│   │   ├── my-items/        # User's items
│   │   ├── notifications/   # Notifications
│   │   ├── profile/         # User profile
│   │   ├── report/          # Report lost/found items
│   │   ├── search/          # Search page
│   │   └── settings/        # Settings
│   ├── components/          # Reusable components
│   │   ├── features/        # Feature components
│   │   ├── layout/          # Layout components
│   │   └── ui/              # UI components
│   ├── contexts/            # React contexts
│   ├── hooks/               # Custom hooks
│   ├── lib/                 # Utilities & configs
│   └── types/               # TypeScript types
├── public/                  # Static assets
└── ...config files
```

---

## 🌐 Deployment

### Deploy to Vercel

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https://github.com/MUTHUKUMARAN-K-1/FINDX)

1. Click the button above or go to [vercel.com](https://vercel.com)
2. Import your GitHub repository
3. Add environment variables in the Vercel dashboard
4. Deploy!

> **Important**: After deployment, add your Vercel domain to Firebase Authentication's authorized domains.

---

## 📄 Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `NEXT_PUBLIC_FIREBASE_API_KEY` | Firebase API key | ✅ |
| `NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN` | Firebase auth domain | ✅ |
| `NEXT_PUBLIC_FIREBASE_PROJECT_ID` | Firebase project ID | ✅ |
| `NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET` | Firebase storage bucket | ✅ |
| `NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID` | Firebase messaging sender ID | ✅ |
| `NEXT_PUBLIC_FIREBASE_APP_ID` | Firebase app ID | ✅ |
| `NEXT_PUBLIC_GEMINI_API_KEY` | Google Gemini API key | ✅ |

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📝 License

This project is licensed under the MIT License.

---

## 👨‍💻 Author

**Muthukumaran K**

- GitHub: [@MUTHUKUMARAN-K-1](https://github.com/MUTHUKUMARAN-K-1)

---

<div align="center">

⭐ **If you found this project helpful, please give it a star!** ⭐

</div>
