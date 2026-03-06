# Stypleguide for GGB Meal Prep project

## naming
- folders with dashes 
- files with underscores

## GGB
- GGB stands for Grain Green Been from a grain, a green, a been
- GGB capitalized
- We are loose about "green", it can be any vegetable, no matter the colour. Though, anything green with every meal is important to us. 
- Grain is food from grain like bread or rice or barley as well as high-carb sides, like sweet-potatoes, taco, wraps, nachos, potatoes.

## Recipes
- Keep it short, dont mention washing and cleaning the vegetables or peeling the onions or shaking the cilantro or salat. This is not a cooking school. Instead, a step starts with cutting or grading or similar...
- Rice is just "cook the rice according to instructions on the package" dont go into detail

## German
Use infinitive wherever possible, like "Zwiebeln fein hacken.", otherise "du" form, never use formal "Sie".
Use space between numbers and units "200 g".
Unit's short form uncapitalized and no dots. correct: 15 min wrong: 15 Min.

## Pipeline Info
### images in md
Pandoc wraps every ![...]() in a <figure>. The CSS has figure { break-inside: avoid } which prevents splitting across pages — so if the remaining space on the page is too small,       
  WeasyPrint pushes the entire figure to the next page. Images also default to full column width (max-width: 100%), making them tall and hard to fit.                                                
                                                                                                                                                                                                 
  1. Control size per image in the markdown (Pandoc attribute syntax):                                                                                                                               
  ![Simple salad](images/toplevel-imgs/salad-as-side.jpg){width=50%}
  Smaller image = more likely to fit where you placed it.                                                                                                                                                                                   
  2. Float the image so text wraps around it — best for in-text images in a plan document:                                                                                                           
  ![Simple salad](images/toplevel-imgs/salad-as-side.jpg){.float-right}                                                                                                                              
  Then add CSS for .float-right figure or figure.float-right.                                                                                                                                        
     
  3. Set a global max-height for non-recipe images so they never crowd a page. 
  
  ### Color scheme pdf
  ┌──────────────────┬─────────┬─────────────────┐
  │       Role       │   Hex   │                 │
  ├──────────────────┼─────────┼─────────────────┤
  │ h1, h2, meta bar │ #1e7896 │ ocean teal-blue │
  ├──────────────────┼─────────┼─────────────────┤
  │ h3, h4           │ #165f78 │ deeper sea blue │
  ├──────────────────┼─────────┼─────────────────┤
  │ h2 underline     │ #a8d4e0 │ pale sky/water  │
  └──────────────────┴─────────┴─────────────────┘

  ### How to make the step image grids
  python3 lib/make_grid.py "images/chili-sin-carne/[1-8]_*.jpg" 4 2 images/chili-sin-carne/steps_grid.jpg

## Frontmatters

  The recipe frontmatter only contains:                  
                                                                                                
  - prep_time, cook_time, servings, kcal_per_serving, image, language
  ← used by recipe-metadata.lua 
  - title (by extract_metadata() for HTML chapter index)