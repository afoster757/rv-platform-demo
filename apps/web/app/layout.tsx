import './styles.css';

export const metadata = {
  title: 'VisionCast Platform Demo',
  description: 'Fictional DevOps demo for CDN, licensing, and content entitlement flows.'
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
