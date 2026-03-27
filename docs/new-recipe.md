# New Recipe Template

Copy this file to `text/<lang>/recipes/<recipe-slug>.md` and fill in your content.
The filename (without `.md`) is used as the slug — keep it lowercase with hyphens.

Omit any frontmatter fields that don't apply (e.g. `kcal_per_serving` is optional).

```markdown

---
title: "Recipe Title"
language: "en"
date: 2026-01-01
prep_time: "15 mins"
cook_time: "30 mins"
servings: 4
kcal_per_serving: 500
image: "images/<recipe-slug>/main.jpg"
in_mealplan: "01_GGB-starter-week2.md"
---

# Recipe Title

## Ingredients

<table class="shopping-list">
<tbody>
<tr><td>400g</td><td>Ingredient one</td></tr>
<tr><td>200g</td><td>Ingredient two</td></tr>
<tr><td>2 cloves</td><td>Garlic</td></tr>
<tr><td>1 tbsp</td><td>Olive oil</td></tr>
<tr><td>Spices</td><td>Salt, pepper, cumin</td></tr>
</tbody>
</table>

## Why this dish

A short paragraph explaining why this recipe fits the GGB method and what makes
it worth cooking. Mention which GGB pillar it hits (Grain, Green, Bean) and any
meal prep advantages.

## Instructions

![Step overview](images/<recipe-slug>/steps-grid.jpg)

1. First step.
2. Second step.
3. Third step.
4. Continue until done.
5. Serve and enjoy.

## Macros and kcal

```


## Notes

- The ingredient table uses `<table class="shopping-list">` — this is required
  for the correct column alignment (quantity right, ingredient left).
- The `image` field in the frontmatter is the recipe hero image shown below the
  title. The image in the Instructions section is optional and separate.
- `language` must match an entry in `lib/lua/recipe-metadata.lua` for the
  metadata bar labels to be translated. Currently supported: `en`, `de`.
- Place recipe images in `images/<recipe-slug>/`.
- The recipe must be listed in the plan's `included_recipes` field to appear in
  the PDF and EPUB.

## images
- The recipe needs a 16x9 hero image, ideally of the meal on my dish or white dish.
- In the ingredient section there should be a foto grid with 4-8 step photos 1x1. Example for image grid maker:  `python3 lib/make_grid.py "images/chili-sin-carne/[1-8]_*.jpg" 4 2 images/chili-sin-carne/steps_grid.jpg` 
- images are in the image/{slug} folder. When they are not or not enough, look under images/reuse-imgs if you can find ingredient or meals to combine. If this is not enough, write a prompt for nano banana, so I can generate the missing image for free manually.

## kcal calculation
In the end calculate the macros and kcal. Refer to "fatsecret {ingredient} calories" for calory websearch.
