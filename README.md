# Pinelaki.com Content Backup

This repository is an archived snapshot of all content from **[pinelaki.com](https://pinelaki.com)** crawled on **2026-03-11**.

It serves as a **content reference** for rebuilding the website with a modern, faster design (Firebase + Vite stack).

## Structure

```
pages/
  home.md                          — Homepage
  _services-group-what-we-do_.md  — Services landing page
  _expert-auto-body-repair-*.md   — Auto Body Repair service page
  _headlight-restoration-*.md     — Headlight Restoration service page
  _collision-repair-*.md          — Collision Repair service page
  _pricing_.md                    — Pricing page
  _blog_.md                       — Blog listing
  _contact-us_.md                 — Contact page
  _product_*.md                   — Individual product pages
  _blog-post-slug_.md             — Individual blog posts
  ...
```

Each `.md` file includes:
- **YAML frontmatter** with `url`, `title`, and `crawled` date
- **Full markdown content** of the page

## Key Content Summary

| Section | URLs/Files found |
|---------|-----------|
| Services | Auto Body Repair, Headlight Restoration, Collision Repair |
| Products | Touch-Up Paint, Clear Coat Varnish, Spray Paint, 1K/2K Clear |
| Blog | 20+ articles (Paint Code locations, how-to guides) |
| Media | 114 unique images locally archived |
| Contact | +357 99228438 · info@pinelaki.com · Mesokeleos 15, Nicosia |

## Media Archive

All media (images) from the old website have been archived to overcome live-site scraping protections.

- **`media/`**: Contains the physical image files downloaded from `pinelaki.com/wp-content/uploads/`
- **`media-map.json`**: A mapping file that links each page URL to the local, downloaded image files used on that page. Useful for programmatic rebuilding.

## Business Details Extracted

- **Phone:** +357 99 228438
- **Email:** info@pinelaki.com  
- **Address:** Mesokeleos 15, Pallouriotissa 1042, Nicosia, Cyprus
- **Facebook:** https://www.facebook.com/pinelakicy
- **Twitter:** @pinelakicy
- **Founded:** 1991 (35+ years experience)
- **Warranty:** 6 years on paint jobs
- **Core services:** Car Body Repair, Painting, Headlight Restoration, Collision Repair, DIY Touch-Up Paint

## Usage

Use the content in `/pages` to:
1. **Port copy**: Copy headings, descriptions, and body text into the new site's CMS
2. **SEO**: Reuse meta titles and descriptions (found in the frontmatter sourced from og:title / og:description)
3. **Image URLs**: All image URLs from `pinelaki.com/wp-content/uploads/` are referenced in the markdown — download and port to new hosting
4. **Reviews**: Customer testimonials are captured in the homepage markdown

## New Website

The new website is being built at:
- **Staging:** https://app.pinelaki.com  
- **Repo:** `kotchounian/pinelaki-antigravity`
- **Stack:** Vite + Firebase Hosting + FireCMS
