import { LoginForm } from "@/components/login-form";

export default function LoginPage() {
  return (
    <div className="flex min-h-screen w-full items-center justify-center p-6 md:p-10 bg-gray-50">
      <div className="w-full max-w-sm">
        <LoginForm />
      </div>
    </div>
  );
}
