import { redirect } from 'next/navigation'

interface PageProps {
  params: Promise<{ id: string }>
}

export default async function JobRedirectPage({ params }: PageProps) {
  const { id } = await params
  // Redirect to the correct authenticated route
  redirect(`/(authenticated)/jobs/${id}`)
}
