@echo off
echo [INFO] Scaffolding Flutter Architecture with Provider...

:: --- CORE LAYER ---
mkdir lib\core\constants
mkdir lib\core\theme
mkdir lib\core\utils
mkdir lib\core\widgets

:: --- AUTH FEATURE ---
mkdir lib\features\auth\data
mkdir lib\features\auth\domain
mkdir lib\features\auth\presentation\providers
mkdir lib\features\auth\presentation\screens

:: --- PROMPT GENERATOR FEATURE ---
mkdir lib\features\prompt_generator\data
mkdir lib\features\prompt_generator\domain
mkdir lib\features\prompt_generator\presentation\providers
mkdir lib\features\prompt_generator\presentation\screens
mkdir lib\features\prompt_generator\presentation\widgets

:: --- PROMPT VAULT FEATURE ---
mkdir lib\features\prompt_vault\data
mkdir lib\features\prompt_vault\domain
mkdir lib\features\prompt_vault\presentation\providers
mkdir lib\features\prompt_vault\presentation\screens

echo [SUCCESS] Folders created! Check your lib directory in VS Code.
pause