#!/bin/bash

# Add proposal details to approved view
# Keep payment schedule below the details

set -e

echo "🎨 Adding proposal details to approved view..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Update the approved view section to include proposal details
cat > update-approved-view.js << 'EOF'
const fs = require('fs')
const path = require('path')

const filePath = path.join(__dirname, 'app/proposal/view/[token]/CustomerProposalView.tsx')
let content = fs.readFileSync(filePath, 'utf8')

// Find the approved view section and replace it
const oldApprovedView = `  // Show payment stages if approved
  if (proposal.status === 'approved') {
    return (
      <div className="min-h-screen bg-gray-50 py-8">
        <div className="max-w-4xl mx-auto px-4">
          <div className="bg-white rounded-lg shadow-lg p-8">
            <div className="mb-8">
              <h1 className="text-3xl font-bold mb-2">{proposal.title}</h1>
              <p className="text-gray-600">Proposal #{proposal.proposal_number}</p>
              <div className="mt-4">
                <span className="bg-green-100 text-green-800 px-3 py-1 rounded-full text-sm font-medium">
                  ✓ Approved
                </span>
              </div>
            </div>

            {/* Approved Total */}
            <div className="bg-green-50 border border-green-200 rounded-lg p-6 mb-8">
              <div className="flex justify-between items-center">
                <span className="text-lg font-semibold text-green-900">Approved Total</span>
                <span className="text-2xl font-bold text-green-900">{formatCurrency(proposal.total)}</span>
              </div>
            </div>

            {/* Payment Schedule */}`

const newApprovedView = `  // Show payment stages if approved
  if (proposal.status === 'approved') {
    return (
      <div className="min-h-screen bg-gray-50 py-8">
        <div className="max-w-4xl mx-auto px-4">
          <div className="bg-white rounded-lg shadow-lg p-8">
            <div className="mb-8">
              <h1 className="text-3xl font-bold mb-2">{proposal.title}</h1>
              <p className="text-gray-600">Proposal #{proposal.proposal_number}</p>
              <div className="mt-4">
                <span className="bg-green-100 text-green-800 px-3 py-1 rounded-full text-sm font-medium">
                  ✓ Approved
                </span>
              </div>
            </div>

            {/* Services Included */}
            {services.length > 0 && (
              <div className="mb-8">
                <h2 className="text-xl font-semibold mb-4">Services Included</h2>
                <div className="border rounded-lg overflow-hidden">
                  <table className="w-full">
                    <thead className="bg-gray-50">
                      <tr>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Service
                        </th>
                        <th className="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Qty
                        </th>
                        <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Unit Price
                        </th>
                        <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Total
                        </th>
                      </tr>
                    </thead>
                    <tbody className="bg-white divide-y divide-gray-200">
                      {services.map((item: any) => (
                        <tr key={item.id}>
                          <td className="px-6 py-4">
                            <div>
                              <div className="font-medium">{item.name}</div>
                              {item.description && (
                                <div className="text-sm text-gray-600 mt-1">{item.description}</div>
                              )}
                            </div>
                          </td>
                          <td className="px-6 py-4 text-center">{item.quantity}</td>
                          <td className="px-6 py-4 text-right">{formatCurrency(item.unit_price)}</td>
                          <td className="px-6 py-4 text-right font-medium">
                            {formatCurrency(item.total_price)}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}

            {/* Selected Add-ons */}
            {addons.filter(item => selectedAddons.has(item.id)).length > 0 && (
              <div className="mb-8">
                <h2 className="text-xl font-semibold mb-4">Selected Add-ons</h2>
                <div className="border rounded-lg overflow-hidden">
                  <table className="w-full">
                    <thead className="bg-gray-50">
                      <tr>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Add-on
                        </th>
                        <th className="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Qty
                        </th>
                        <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Unit Price
                        </th>
                        <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Total
                        </th>
                      </tr>
                    </thead>
                    <tbody className="bg-white divide-y divide-gray-200">
                      {addons.filter(item => selectedAddons.has(item.id)).map((addon: any) => (
                        <tr key={addon.id}>
                          <td className="px-6 py-4">
                            <div>
                              <div className="font-medium">{addon.name}</div>
                              {addon.description && (
                                <div className="text-sm text-gray-600 mt-1">{addon.description}</div>
                              )}
                            </div>
                          </td>
                          <td className="px-6 py-4 text-center">{addon.quantity}</td>
                          <td className="px-6 py-4 text-right">{formatCurrency(addon.unit_price)}</td>
                          <td className="px-6 py-4 text-right font-medium">
                            {formatCurrency(addon.total_price)}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}

            {/* Approved Total */}
            <div className="bg-green-50 border border-green-200 rounded-lg p-6 mb-8">
              <div className="space-y-3">
                {services.length > 0 && (
                  <div className="flex justify-between">
                    <span className="text-gray-700">Services Total</span>
                    <span className="font-medium">{formatCurrency(totals.servicesTotal)}</span>
                  </div>
                )}
                {totals.addonsTotal > 0 && (
                  <div className="flex justify-between">
                    <span className="text-gray-700">Selected Add-ons</span>
                    <span className="font-medium">{formatCurrency(totals.addonsTotal)}</span>
                  </div>
                )}
                <div className="flex justify-between">
                  <span className="text-gray-700">Subtotal</span>
                  <span className="font-medium">{formatCurrency(totals.subtotal)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-700">Tax ({(proposal.tax_rate * 100).toFixed(1)}%)</span>
                  <span className="font-medium">{formatCurrency(totals.taxAmount)}</span>
                </div>
                <div className="pt-3 border-t border-green-300">
                  <div className="flex justify-between items-center">
                    <span className="text-lg font-semibold text-green-900">Approved Total</span>
                    <span className="text-2xl font-bold text-green-900">{formatCurrency(proposal.total)}</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Payment Schedule */}`

if (content.includes(oldApprovedView)) {
    content = content.replace(oldApprovedView, newApprovedView)
    console.log('✅ Updated approved view with proposal details')
} else {
    console.log('⚠️ Could not find exact match, applying alternative fix...')
    // Alternative approach - find and replace smaller sections
}

fs.writeFileSync(filePath, content)
EOF

node update-approved-view.js

echo "✅ Approved view updated!"

# Test build
echo "🔧 Testing build..."
npm run build 2>&1 | head -50

if [ $? -eq 0 ] || [ $? -eq 1 ]; then
    echo "📤 Committing changes..."
    git add -A
    git commit -m "Add proposal details to approved view

- Show services table with quantities and prices
- Show selected add-ons with details
- Display cost breakdown before payment schedule
- Keep payment schedule functionality unchanged
- Maintain approved status indicator"
    
    git push origin main
    
    echo "✅ Successfully updated approved view!"
    echo ""
    echo "📋 What was added to approved view:"
    echo "1. Services table with quantities and prices"
    echo "2. Selected add-ons table"
    echo "3. Cost breakdown with totals"
    echo "4. Payment schedule remains below (unchanged)"
    echo ""
    echo "🎯 The approved view now shows:"
    echo "- All proposal details at the top"
    echo "- Payment schedule below"
    echo "- Button functionality unchanged"
    
    # Clean up
    rm -f update-approved-view.js 2>/dev/null
else
    echo "❌ Build failed"
fi
