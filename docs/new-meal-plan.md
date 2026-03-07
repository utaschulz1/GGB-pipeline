# New Meal Plan Template

Copy this file to `text/<lang>/plans/<plan-slug>.md` and fill in your content.
The filename (without `.md`) is used as the plan slug and becomes the PDF/EPUB
filename (e.g. `my-plan.md` → `public/en/my-plan.pdf`).

Also add the slug to `settings/build.yml` under `plans:` so it gets built.

---

```markdown
---
title: "Plan Title"
description: "One-line description of the plan"
language: "en"
cover-image: "images/<recipe-slug>/main.jpg"
included_recipes:
  - recipe-slug-one
  - recipe-slug-two
  - recipe-slug-three
---

# Plan Title

## The Plan

A short introduction to what this meal plan offers and who it is for.

## Who is this plan for

✓ For people who ...

✓ Designed for ...

## What is in it

Brief summary: X cooking sessions for Y days of dinner for Z people.

## Recipes in this plan

1. Recipe One [Jump to recipe](#anchor-one)
2. Recipe Two [Jump to recipe](#anchor-two)
3. Recipe Three [Jump to recipe](#anchor-three)

## Equipment

Minimum: list the essentials.

Optional: list nice-to-haves.

## The Shopping List for this Plan

<table class="shopping-list">
<tbody>
<tr><td class="sl-category" colspan="2">Grains</td></tr>
<tr><td>500g</td><td>Rice</td></tr>
<tr><td class="sl-category" colspan="2">Greens</td></tr>
<tr><td>200g</td><td>Spinach</td></tr>
<tr><td class="sl-category" colspan="2">Beans</td></tr>
<tr><td>400g</td><td>Lentils</td></tr>
<tr><td class="sl-category" colspan="2">Other</td></tr>
<tr><td>400ml</td><td>Coconut milk</td></tr>
<tr><td class="sl-category" colspan="2">Spices</td></tr>
<tr><td>1 tbsp</td><td>Turmeric</td></tr>
</tbody>
</table>

## Schedule

### Day 1
What to cook, what to prepare.

### Day 2
What to reheat or cook fresh.

### Day 3
What to reheat or cook fresh.
```

---

## Notes

- `included_recipes` lists recipe file slugs (filenames without `.md`) in the
  order they appear in the PDF and EPUB. The recipe files must exist in
  `text/<lang>/recipes/`.
- `cover-image` is used as the PDF cover and EPUB cover image. Use a landscape
  or portrait photo — whatever fits best on a title page.
- The shopping list uses `<table class="shopping-list">` for correct column
  alignment. Category rows use `<td class="sl-category" colspan="2">`.
- Jump-to-recipe anchors in the recipe list must match the heading ID Pandoc
  generates from the recipe title (lowercase, spaces to hyphens).
- After adding a new plan, add its slug to `settings/build.yml`:
  ```yaml
  plans:
    - existing-plan-slug
    - new-plan-slug
  ```
