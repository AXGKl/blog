# Gimp Basics

Every second month or so I need to do sth with it and that dt is unfortunately too big, to
have the knowledge not constantly swapped out.

So lets begin writing some basics. 

## Alpha: Transparent Backgrounds

On OSX I loved Keynote's Instant Alpha Feature to get rid of Background colors.

With gimp its actually really simple as well:

1. Open Image
1. right click -> Choose "Colors" in context menu -> "Color to Alpha"
1. Save as png (hit "Save gamma", uncheck "Save background color"



## Pixelperfect Editted PDFs

When you need to *edit* pdfs, libreoffice draw is a super tool. But for complex pdfs, it often
screws some formatting of the original.

When the intended editing is not to change but to add stuff, like signatures or form data then gimp
can help:

1. Open the pdf in gimp, choose resolution from 100.000 to 200.000 
1. Export to pdf, check: "export layers as pages"
1. Open in libreoffice draw - the formatting is now as in the original since its a set of images
   now, no text.

   Filessize will explode though, clear, but that would be the case with a print -> sign -> fill out
   / scan cycle as well.

## Layer Merging

Alt-i (Image) -> l (Merge Layers) -> confirm. Do this after copy - paste in place 

## Changing Text on a Scanned PDF

- Needed to change an address but the pdf was just an image.
- You have to cut and paste the letters and re-assemble them for the new text - but its fast:
    - Rectangle select -> copy (ctrl-c) -> paste in place, move the letter to destination.
    - Then merge layers (alt-i, l, confirm)
    







