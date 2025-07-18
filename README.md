# Guide to Windows Registry Context Menu Variables

## The Core Principle: Context is Everything

When a user right-clicks, the Windows shell determines the context (e.g., clicking on a file, a folder, or a folder's background) and makes a specific set of variable placeholders (like `%L` or `%V`) available for expansion. A command's behavior depends entirely on which variables are available and expanded in that specific context.

---

## Key Variables and Their Scopes

| Variable | Description | Valid Context Example |
| :--- | :--- | :--- |
| `%1` or `%L` | The full path to the selected **item**. This can be a file or a folder. `%L` is generally preferred to handle long file names. | `HKEY_CLASSES_ROOT\Directory\shell` (on the folder itself) |
| `%V` | The full path to the **current folder**. This is only available when clicking on the background of a folder or on the Desktop. | `HKEY_CLASSES_ROOT\Directory\Background\shell` |
| `%*` | A list of all selected items. Used for actions that can handle multiple files/folders at once. | `HKEY_CLASSES_ROOT\*\shell` |

---

## Implementation Pattern: Centralized Command Store

This project uses an advanced architecture with a centralized `CommandStore`. Each module's `install.ps1` acts as a pure configuration file, defining *what* the menu item should do. The main `Manage-QuickActions.ps1` script then reads these configurations and efficiently writes all the necessary registry keys.

### Module Configuration (`install.ps1`)

Each module defines its properties via variables:

-   `$moduleName`: A unique identifier (e.g., "OpenInVSCode").
-   `$menuText`: The text displayed in the context menu.
-   `$targetContexts`: An array of contexts where the item appears (e.g., `"Folder"`, `"LnkFile"`).
-   `$commandTemplate`: A string defining the command to be run, using `{ActionScriptPath}` as a placeholder for the module's `action.ps1` file.
-   `$icon`: The icon to display.

### Icon Configuration Note

When specifying an icon for an executable (`.exe`), it is best to use the **command name** as it's registered in your system's PATH, rather than the full filename.

-   **Correct:** `$icon = "code"`
-   **Correct:** `$icon = "notepad++"`
-   **Incorrect:** `$icon = "code.exe"`

The main script will automatically resolve the command name to the correct executable path. For `.ico` files or system icons (like `imageres.dll,-112`), you can provide the path directly.