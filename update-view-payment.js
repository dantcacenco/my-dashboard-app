const fs = require('fs')
const path = require('path')

const filePath = path.join(__dirname, 'app/proposal/view/[token]/CustomerProposalView.tsx')
let content = fs.readFileSync(filePath, 'utf8')

// Add useSearchParams import
if (!content.includes("useSearchParams")) {
  content = content.replace(
    "import { useRouter } from 'next/navigation'",
    "import { useRouter, useSearchParams } from 'next/navigation'"
  )
}

// Add payment success handling
const hookSection = content.match(/export default function CustomerProposalView.*?\{[\s\S]*?const router = useRouter\(\)/)[0]
if (hookSection && !content.includes('searchParams')) {
  content = content.replace(
    'const router = useRouter()',
    `const router = useRouter()
  const searchParams = useSearchParams()`
  )
}

// Add success message display
const successHandling = `
  // Show success message if payment just completed
  useEffect(() => {
    if (searchParams.get('payment') === 'success') {
      // Refresh to get updated payment status
      refreshProposal()
      // Show success toast if you have a toast library
      // toast.success('Payment successful!')
    }
  }, [searchParams])`

// Insert after the existing useEffect
const existingEffect = content.indexOf('}, [proposal.status])')
if (existingEffect > -1 && !content.includes("searchParams.get('payment')")) {
  content = content.slice(0, existingEffect + 23) + successHandling + content.slice(existingEffect + 23)
}

fs.writeFileSync(filePath, content)
console.log('✅ Updated CustomerProposalView with payment success handling')
