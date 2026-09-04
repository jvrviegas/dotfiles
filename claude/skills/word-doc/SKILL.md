---
name: word-doc
description: "Use this skill whenever the user wants to create or edit Word documents (.docx files). This includes creating reports, memos, letters, proposals, or any professional document, as well as editing existing .docx files by modifying text, adding content, or restructuring. Trigger on mentions of 'Word doc', 'word document', '.docx', 'report', 'memo', 'letter', 'proposal', or any request to produce a formatted document. Also trigger when the user wants to read or extract content from .docx files, insert images, work with tables, or convert between formats. Do NOT use for PDFs, spreadsheets, or Google Docs."
---

# Word Document Creation and Editing

This skill covers creating new .docx files from scratch and editing existing ones. A .docx file is a ZIP archive of XML files following the Office Open XML (OOXML) standard.

## Decision Table

| Task | Method |
|------|--------|
| Create a new document | Write a Node.js script using `docx` (npm package) |
| Read/extract text | Use `pandoc` to convert to markdown |
| Edit an existing document | Unzip, edit the XML directly, rezip |
| Convert .doc to .docx | Use LibreOffice headless mode |

---

## Brand Style Guide

All documents should follow these conventions for a consistent, professional look. These are based on the team's established document style and should be used as the default unless the user specifies otherwise.

### Color Palette

| Role | Hex Code | Usage |
|------|----------|-------|
| Primary blue | `#2E5C8A` | Headings, title text, header border, horizontal rules |
| Body text | `#333333` | Main paragraph text |
| Subtle text | `#666666` | Header/footer text, subtitle/description text |
| Table border | `#CCCCCC` | All table cell borders, footer top border |
| Table header bg | `#2E5C8A` | Table header row background |
| Table header text | `#FFFFFF` | White text on table header rows |

### Typography

- **Default font**: Arial for everything (body, headings, headers, footers, tables)
- **Body text**: 11pt (size: 22 in half-points), color `#333333`
- **Heading 1**: 18pt (size: 36), bold, color `#2E5C8A`, spacing before: 360, after: 200, outlineLevel: 0
- **Heading 2**: 14pt (size: 28), bold, color `#2E5C8A`, spacing before: 280, after: 160, outlineLevel: 1
- **Title**: 26pt (size: 52), bold, color `#2E5C8A`, spacing after: 80
- **Subtitle/description**: 12pt (size: 24), color `#666666`, with a bottom border (single, color `#2E5C8A`, size 8, space 8) and spacing after: 300

### Page Layout

- US Letter (12240 x 15840 DXA)
- 1-inch margins all around (1440 DXA)
- Content width: 9360 DXA

### Header Style

A single line of text in the header, with a bottom border line underneath:
- Font: Arial, 9pt (size: 18), color `#666666`
- Bottom border: single line, color `#2E5C8A`, size 6, space 4
- Format: `"Company Name  |  Document Title"`

### Footer Style

Right-aligned page number with a top border line above:
- Font: Arial, 8pt (size: 16), color `#666666`
- Top border: single line, color `#CCCCCC`, size 4, space 4
- Format: `"Page "` followed by auto page number field

### Table Style

- Width: full content width (9360 DXA) using `WidthType.DXA`
- Borders: single, color `#CCCCCC`, size 1
- Header row: background `#2E5C8A`, text white (`#FFFFFF`), bold, 10pt (size: 20)
- Data rows: no background, text in body color, 10pt (size: 20)
- Cell margins: top/bottom 80, left/right 120
- Vertical alignment: center

### List Style

- Bullet lists: `●` (filled circle) at level 0, `○` at level 1, `■` at level 2
- Numbered lists: `%1.` decimal format
- Indent: left 720, hanging 360

---

## Creating New Documents

Use the `docx` npm package (install with `npm install docx` if not already available). Write a Node.js script that constructs the document programmatically, then save the buffer to a file.

### Full Branded Template

This template produces a document matching the brand style. Use it as the starting point for all new documents:

```javascript
const fs = require("fs");
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  ImageRun, Header, Footer, AlignmentType, PageOrientation,
  LevelFormat, ExternalHyperlink, HeadingLevel, BorderStyle,
  WidthType, ShadingType, PageNumber, PageBreak, TableOfContents,
  Bookmark, InternalHyperlink, FootnoteReferenceRun,
  TabStopType, TabStopPosition, VerticalAlign
} = require("docx");

// --- Brand constants ---
const BRAND = {
  primaryBlue: "2E5C8A",
  bodyColor: "333333",
  subtleColor: "666666",
  borderColor: "CCCCCC",
  white: "FFFFFF",
  font: "Arial",
};

const cellBorder = { style: BorderStyle.SINGLE, size: 1, color: BRAND.borderColor };
const allBorders = { top: cellBorder, bottom: cellBorder, left: cellBorder, right: cellBorder };
const cellMargins = { top: 80, bottom: 80, left: 120, right: 120 };

const doc = new Document({
  styles: {
    default: {
      document: {
        run: { font: BRAND.font, size: 22, color: BRAND.bodyColor }
      }
    },
    paragraphStyles: [
      {
        id: "Heading1", name: "Heading 1",
        basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 36, bold: true, font: BRAND.font, color: BRAND.primaryBlue },
        paragraph: { spacing: { before: 360, after: 200 }, outlineLevel: 0 }
      },
      {
        id: "Heading2", name: "Heading 2",
        basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 28, bold: true, font: BRAND.font, color: BRAND.primaryBlue },
        paragraph: { spacing: { before: 280, after: 160 }, outlineLevel: 1 }
      },
    ]
  },
  numbering: {
    config: [
      {
        reference: "bullets",
        levels: [
          { level: 0, format: LevelFormat.BULLET, text: "\u25CF", alignment: AlignmentType.LEFT,
            style: { paragraph: { indent: { left: 720, hanging: 360 } } } },
          { level: 1, format: LevelFormat.BULLET, text: "\u25CB", alignment: AlignmentType.LEFT,
            style: { paragraph: { indent: { left: 1440, hanging: 360 } } } },
          { level: 2, format: LevelFormat.BULLET, text: "\u25A0", alignment: AlignmentType.LEFT,
            style: { paragraph: { indent: { left: 2160, hanging: 360 } } } },
        ]
      },
      {
        reference: "numbers",
        levels: [{
          level: 0, format: LevelFormat.DECIMAL, text: "%1.",
          alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 720, hanging: 360 } } }
        }]
      }
    ]
  },
  sections: [{
    properties: {
      page: {
        size: { width: 12240, height: 15840 },
        margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 }
      }
    },
    headers: {
      default: new Header({
        children: [new Paragraph({
          border: { bottom: { style: BorderStyle.SINGLE, color: BRAND.primaryBlue, size: 6, space: 4 } },
          children: [new TextRun({
            text: "Company Name  |  Document Title",
            font: BRAND.font, size: 18, color: BRAND.subtleColor
          })]
        })]
      })
    },
    footers: {
      default: new Footer({
        children: [new Paragraph({
          alignment: AlignmentType.RIGHT,
          border: { top: { style: BorderStyle.SINGLE, color: BRAND.borderColor, size: 4, space: 4 } },
          children: [
            new TextRun({ text: "Page ", font: BRAND.font, size: 16, color: BRAND.subtleColor }),
            new TextRun({ children: [PageNumber.CURRENT], font: BRAND.font, size: 16, color: BRAND.subtleColor })
          ]
        })]
      })
    },
    children: [
      // --- Title block ---
      new Paragraph({
        spacing: { after: 80 },
        children: [new TextRun({
          text: "Document Title",
          bold: true, font: BRAND.font, size: 52, color: BRAND.primaryBlue
        })]
      }),
      // --- Subtitle / description with bottom rule ---
      new Paragraph({
        spacing: { after: 300 },
        border: { bottom: { style: BorderStyle.SINGLE, color: BRAND.primaryBlue, size: 8, space: 8 } },
        children: [new TextRun({
          text: "A brief description of the document purpose.",
          font: BRAND.font, size: 24, color: BRAND.subtleColor
        })]
      }),
      // --- Body content starts here ---
      new Paragraph({
        heading: HeadingLevel.HEADING_1,
        children: [new TextRun("Section Title")]
      }),
      new Paragraph({
        spacing: { after: 200 },
        children: [new TextRun("Body paragraph text goes here.")]
      }),
    ]
  }]
});

Packer.toBuffer(doc).then(buffer => {
  fs.writeFileSync("output.docx", buffer);
  console.log("Created output.docx");
});
```

### Building a Branded Table

```javascript
// Helper: create a header cell (blue background, white bold text)
function headerCell(text, width) {
  return new TableCell({
    borders: allBorders,
    width: { size: width, type: WidthType.DXA },
    shading: { fill: BRAND.primaryBlue, type: ShadingType.CLEAR },
    margins: cellMargins,
    verticalAlign: VerticalAlign.CENTER,
    children: [new Paragraph({
      children: [new TextRun({
        text, bold: true, font: BRAND.font, size: 20, color: BRAND.white
      })]
    })]
  });
}

// Helper: create a data cell
function dataCell(text, width) {
  return new TableCell({
    borders: allBorders,
    width: { size: width, type: WidthType.DXA },
    margins: cellMargins,
    verticalAlign: VerticalAlign.CENTER,
    children: [new Paragraph({
      children: [new TextRun({
        text, font: BRAND.font, size: 20, color: BRAND.bodyColor
      })]
    })]
  });
}

// Example: 3-column table, full width (9360 DXA)
const colWidths = [3120, 3120, 3120]; // must sum to 9360

new Table({
  width: { size: 9360, type: WidthType.DXA },
  columnWidths: colWidths,
  rows: [
    new TableRow({ children: [
      headerCell("Column A", colWidths[0]),
      headerCell("Column B", colWidths[1]),
      headerCell("Column C", colWidths[2]),
    ]}),
    new TableRow({ children: [
      dataCell("Value 1", colWidths[0]),
      dataCell("Value 2", colWidths[1]),
      dataCell("Value 3", colWidths[2]),
    ]}),
  ]
})
```

### Units and Page Sizes

All measurements in docx-js use DXA (twentieths of a point). 1 inch = 1440 DXA.

| Paper Size | Width (DXA) | Height (DXA) | Content Width (1" margins) |
|------------|-------------|--------------|---------------------------|
| US Letter | 12,240 | 15,840 | 9,360 |
| A4 | 11,906 | 16,838 | 9,026 |

The default is A4, so always set page size explicitly for US documents.

For **landscape orientation**, pass the portrait dimensions and let docx-js handle the swap:
```javascript
size: {
  width: 12240,   // short edge
  height: 15840,  // long edge
  orientation: PageOrientation.LANDSCAPE  // library swaps internally
}
// Content width becomes: 15840 - left margin - right margin
```

### Lists

Never insert bullet characters manually (like `"• Item"` or `"\u2022 Item"`). Instead, use the numbering config defined in the template above:

```javascript
// Bullet item
new Paragraph({
  numbering: { reference: "bullets", level: 0 },
  children: [new TextRun("Bullet item")]
})

// Numbered item
new Paragraph({
  numbering: { reference: "numbers", level: 0 },
  children: [new TextRun("Numbered item")]
})

// Nested bullet (level 1)
new Paragraph({
  numbering: { reference: "bullets", level: 1 },
  children: [new TextRun("Sub-bullet item")]
})
```

Using the same `reference` value continues the sequence. Use a different `reference` to restart numbering.

### Images

The `type` property is mandatory for ImageRun. All three `altText` fields are required.

```javascript
new Paragraph({
  children: [new ImageRun({
    type: "png",  // png, jpg, jpeg, gif, bmp, svg
    data: fs.readFileSync("image.png"),
    transformation: { width: 400, height: 300 },  // pixels
    altText: { title: "Photo", description: "A landscape photo", name: "landscape" }
  })]
})
```

### Page Breaks

Page breaks must be inside a Paragraph (standalone ones create invalid XML):

```javascript
new Paragraph({ children: [new PageBreak()] })
// or
new Paragraph({ pageBreakBefore: true, children: [new TextRun("Starts on new page")] })
```

### Hyperlinks

```javascript
// External
new Paragraph({
  children: [new ExternalHyperlink({
    children: [new TextRun({ text: "Visit site", style: "Hyperlink" })],
    link: "https://example.com"
  })]
})

// Internal (bookmark at destination + link from source)
new Paragraph({
  heading: HeadingLevel.HEADING_1,
  children: [new Bookmark({ id: "sec1", children: [new TextRun("Section 1")] })]
})
new Paragraph({
  children: [new InternalHyperlink({
    children: [new TextRun({ text: "Jump to Section 1", style: "Hyperlink" })],
    anchor: "sec1"
  })]
})
```

### Footnotes

```javascript
const doc = new Document({
  footnotes: {
    1: { children: [new Paragraph("Source: Annual Report 2024")] },
  },
  sections: [{
    children: [new Paragraph({
      children: [
        new TextRun("Revenue grew 15%"),
        new FootnoteReferenceRun(1),
      ]
    })]
  }]
});
```

### Table of Contents

Headings must use `HeadingLevel` (not custom styles) for the TOC to detect them:

```javascript
new TableOfContents("Table of Contents", {
  hyperlink: true,
  headingStyleRange: "1-3"
})
```

### Things That Will Break Your Document

- Using `\n` for line breaks (use separate Paragraph objects instead)
- Manual bullet characters (`"• "`, `"\u2022"`) instead of numbering config
- `WidthType.PERCENTAGE` on tables (breaks in Google Docs)
- Missing `type` on ImageRun
- PageBreak outside a Paragraph
- Using tables as horizontal rules or dividers (cells have minimum height; use a Paragraph with a bottom border instead)
- Using `ShadingType.SOLID` instead of `ShadingType.CLEAR` (produces black backgrounds)
- Not setting both `columnWidths` on Table AND `width` on each cell

---

## Editing Existing Documents

Since .docx is a ZIP of XML files, editing means: unzip, modify the XML, rezip.

### Step 1: Extract

```bash
mkdir -p unpacked
cd unpacked && unzip -o ../document.docx && cd ..
```

The key file is `unpacked/word/document.xml` which contains the document body.

### Step 2: Read and Understand

Before editing, read the document structure:
```bash
# Quick text extraction
pandoc document.docx -o content.md

# Or examine the raw XML
cat unpacked/word/document.xml
```

The body content lives inside `<w:body>`. Each paragraph is a `<w:p>` element containing runs (`<w:r>`) which hold text (`<w:t>`).

### Step 3: Edit the XML

Use the Edit tool to make targeted replacements in the XML files. Common edits:

**Replace text:**
Find the `<w:t>` element containing the text and replace it.

**Add a paragraph:**
Insert a new `<w:p>` element. A minimal paragraph:
```xml
<w:p>
  <w:r>
    <w:t>New paragraph text</w:t>
  </w:r>
</w:p>
```

**Add formatting:**
Formatting goes inside `<w:rPr>` (run properties) within a run:
```xml
<w:r>
  <w:rPr>
    <w:b/>          <!-- bold -->
    <w:i/>          <!-- italic -->
    <w:sz w:val="28"/>  <!-- font size in half-points (28 = 14pt) -->
  </w:rPr>
  <w:t>Formatted text</w:t>
</w:r>
```

**Important XML rules:**
- Add `xml:space="preserve"` to `<w:t>` elements that have leading/trailing whitespace
- Elements inside `<w:pPr>` must follow a specific order: `<w:pStyle>`, `<w:numPr>`, `<w:spacing>`, `<w:ind>`, `<w:jc>`, `<w:rPr>` (last)
- Use smart quote XML entities for professional typography: `&#x2018;` (left single), `&#x2019;` (right single/apostrophe), `&#x201C;` (left double), `&#x201D;` (right double)

### Step 4: Repack

```bash
cd unpacked && zip -r ../output.docx . -x "*.DS_Store" && cd ..
```

### Adding Images to Existing Documents

1. Copy the image file into `unpacked/word/media/`
2. Add a relationship in `unpacked/word/_rels/document.xml.rels`:
   ```xml
   <Relationship Id="rIdNEW" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/myimage.png"/>
   ```
3. Ensure the content type exists in `unpacked/[Content_Types].xml`:
   ```xml
   <Default Extension="png" ContentType="image/png"/>
   ```
4. Insert the drawing XML in document.xml where you want the image:
   ```xml
   <w:drawing>
     <wp:inline distT="0" distB="0" distL="0" distR="0">
       <wp:extent cx="914400" cy="914400"/> <!-- EMUs: 914400 = 1 inch -->
       <wp:docPr id="1" name="Picture 1"/>
       <a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
         <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
           <pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
             <pic:nvPicPr>
               <pic:cNvPr id="1" name="myimage.png"/>
               <pic:cNvPicPr/>
             </pic:nvPicPr>
             <pic:blipFill>
               <a:blip r:embed="rIdNEW"/>
               <a:stretch><a:fillRect/></a:stretch>
             </pic:blipFill>
             <pic:spPr>
               <a:xfrm>
                 <a:off x="0" y="0"/>
                 <a:ext cx="914400" cy="914400"/>
               </a:xfrm>
               <a:prstGeom prst="rect"><a:avLst/></a:prstGeom>
             </pic:spPr>
           </pic:pic>
         </a:graphicData>
       </a:graphic>
     </wp:inline>
   </w:drawing>
   ```

---

## Reading Documents

```bash
# Convert to markdown (preserves basic formatting)
pandoc document.docx -o output.md

# Convert to plain text
pandoc document.docx -t plain -o output.txt

# Extract with tracked changes visible
pandoc --track-changes=all document.docx -o output.md
```

## Format Conversion

```bash
# .doc to .docx
libreoffice --headless --convert-to docx document.doc

# .docx to PDF
libreoffice --headless --convert-to pdf document.docx

# .docx to page images
libreoffice --headless --convert-to pdf document.docx
pdftoppm -jpeg -r 150 document.pdf page
```

## Dependencies

- **Node.js + docx package**: `npm install docx` (for creating new documents)
- **pandoc**: text extraction and format conversion
- **LibreOffice**: .doc conversion and PDF export
- **Poppler** (`pdftoppm`): page-to-image conversion
