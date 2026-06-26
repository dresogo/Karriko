'use client'

import { useSearchParams } from 'next/navigation'

export default function ResetPasswordClient() {
  const searchParams = useSearchParams()
  const token = searchParams.get('token')
  const type = searchParams.get('type')

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="w-full max-w-md space-y-8">
        {/* Header */}
        <div className="text-center">
          <h1 className="text-4xl font-bold text-gray-900">Karriko</h1>
          <h2 className="mt-6 text-2xl font-bold text-gray-900">Neues Passwort setzen</h2>
        </div>

        {/* Form / Messages */}
        <div className="bg-white py-12 px-6 shadow rounded-lg sm:px-12">
          {token && type === 'recovery' ? (
            <>
              {/* TODO: New password form */}
              {/* Password input */}
              {/* Confirm password input */}
              {/* Submit button */}
              {/* Password strength indicator */}
            </>
          ) : (
            <div className="text-center">
              <p className="text-red-600 mb-4">
                ❌ Der Link ist ungültig oder abgelaufen.
              </p>
              <a href="/forgot-password" className="text-emerald-600 hover:text-emerald-500 font-medium">
                Neuen Link anfordern
              </a>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}