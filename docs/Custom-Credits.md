## JSON Structure
Your `credits.json` should be structured as follows:
```jsonc
{
    "categories": [ // List of credit categories
        {
            "name": "Category Name", // Category name
            "developers": [ // List of developers
                {
                    "name": "Developer Name", // Name of developer
                    "icon": "icon-name", // Developer's icon, if it exists
                    "link": "https://example.com", // Developer's social link, can be set to "nolink" if none
                    "description": "Description", // Developer's description
                    "color": "FF0000" // BG color
                }
            ]
        }
    ]
}
```

If a developer has an icon, it should be located in `mods/your-mod/images/credits/credit-icon.png`, and should have a minimum size of `150 by 150`.

## Backwards Compatibility
For compatibility with older Psych Engine mods, you can also use `credits.txt` instead. This file will be parsed instead if `credits.json` is not found.

### TXT Structure
Your `credits.txt` file should be structured as follows:
```
Category Name
Name::icon::description::link::color
Name::icon::description::link::color

Another Category
Name::icon::description::link::color
```