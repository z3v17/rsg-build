# RSG Build System

This is a build system for **RedM**, designed to allow players to build, interact with, and manage objects in the game world. The system includes features such as object placement, deletion, door toggling, and more. 

**
This project is a work in progress in alpha state, many features and improvements are still under development
**

## Key Features

### 1. **Object Building**
- Players can use specific items to build objects in the game world.
- Objects can be dynamically placed, moved, rotated, and adjusted before confirming their position.

### 2. **Build Management**
- **Save Builds:** Builds are saved in a MySQL database, allowing them to persist between sessions.
- **Delete Builds:** Players can delete their own builds or destroy them with dynamite.
- **Toggle Doors:** Doors can be toggled (opened/closed) with dynamic rotations.

### 3. **Dynamic Optimization**
- Builds are loaded and unloaded dynamically based on the player's distance, optimizing server and client performance.

### 4. **Admin Support**
- Admins have special permissions to delete any build, regardless of ownership.

### 5. **Discord Integration**  ----- ON FUTURE UPDATE STILL NOT FINISHED
- The system includes support for sending logs to a Discord webhook, allowing important events like builds or deletions to be recorded.

### 6. **Compatibility**
- Compatible with the RSG Core
- Object interaction via `rsg-target`.

## Requirements
- **RedM** (prerelease build)
- **Dependencies:**
  - `rsg-core`
  - `ox_lib`
  - `oxmysql`

---

## Installation

1. **Clone the Repository:**
   Place the script folder in your server's `resources` directory.

2. **Set Up the Database:**
   Ensure you have a table named `construcciones` in your MySQL database. You can use the following structure:

   ```sql
   CREATE TABLE `construcciones` (
       `id` INT AUTO_INCREMENT PRIMARY KEY,
       `model` VARCHAR(255) NOT NULL,
       `x` FLOAT NOT NULL,
       `y` FLOAT NOT NULL,
       `z` FLOAT NOT NULL,
       `rot_x` FLOAT NOT NULL,
       `rot_y` FLOAT NOT NULL,
       `rot_z` FLOAT NOT NULL,
       `owner` VARCHAR(255) NOT NULL,
       `state` INT DEFAULT 0
   );
