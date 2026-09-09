I need help fixing the category navigation architecture in my Flutter app.

Important:
- Do NOT change my existing UI, layout, widgets, spacing, colors, or design.
- Do NOT redesign anything.
- Keep the current UI exactly as it is.
- Only fix the navigation/state management logic.

Current hierarchy:

Main Category
    ↓
SubCategory Page
    Left Panel = Current level categories
    Right Panel = Selected category's content

Business Rules:
1. If hasChild == true:
   - The category contains only subcategories.
   - It never contains products.
2. If hasChild == false:
   - The category contains only products.
   - It never contains subcategories.
3. Products always exist only at the leaf (end-level) category.
4. A category can never contain both products and subcategories.

Expected behavior:

Main Category click:
- hasChild == true → Open Category Page
- hasChild == false → Open Product Listing

Inside Category Page:

LEFT PANEL:
- Clicking a category with hasChild == true:
  - Do NOT navigate.
  - Just update the right panel to show its subcategories.
- Clicking a category with hasChild == false:
  - Do NOT navigate.
  - Just update the right panel to show its products.

RIGHT PANEL:
- If the user clicks an item with hasChild == true:
  - Open a NEW Category Page for that category.
- If the user clicks an item with hasChild == false:
  - Stay on the SAME page and show its products.
  - Do NOT open another Category Page.

Additional requirements:
- Unlimited nested categories must be supported.
- Back navigation should always restore the previous page state correctly.
- No blank screens.
- Preserve selected index/state correctly.
- Do not introduce special logic only for the first auto-selected category.
- Use the same logic for auto-selected categories and user-selected categories.
- Keep my current UI exactly unchanged.
- Focus only on navigation architecture and state management.