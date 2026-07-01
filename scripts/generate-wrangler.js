const fs = require('fs');
const path = require('path');

const rootDir = path.resolve(__dirname, '..');
const templatePath = path.join(rootDir, 'wrangler.toml.template');
const outputPath = path.join(rootDir, 'wrangler.toml');

// Function to parse .env file content
function parseEnvFile(filePath) {
  if (!fs.existsSync(filePath)) return {};
  const content = fs.readFileSync(filePath, 'utf-8');
  const env = {};
  content.split(/\r?\n/).forEach((line) => {
    // Trim and ignore comments/empty lines
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) return;
    
    // Split by first '=' character
    const match = trimmed.match(/^([^=]+)=(.*)$/);
    if (match) {
      const key = match[1].trim();
      let val = match[2].trim();
      // Remove surrounding quotes if present
      if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
        val = val.slice(1, -1);
      }
      env[key] = val;
    }
  });
  return env;
}

function generate() {
  console.log('Generating wrangler.toml...');

  // 1. Load env files (.env.local has priority, then .env, then process.env)
  const localEnvPath = path.join(rootDir, '.env.local');
  const defaultEnvPath = path.join(rootDir, '.env');
  
  const localEnv = parseEnvFile(localEnvPath);
  const defaultEnv = parseEnvFile(defaultEnvPath);
  
  // Merge configurations
  const envVars = {
    ...defaultEnv,
    ...localEnv,
    ...process.env // System environment variables have ultimate override
  };

  if (!fs.existsSync(templatePath)) {
    console.error(`Error: Template file not found at ${templatePath}`);
    process.exit(1);
  }

  let templateContent = fs.readFileSync(templatePath, 'utf-8');

  // Regex to match ${VAR_NAME}
  const placeholderRegex = /\${([A-Za-z0-9_]+)}/g;
  let hasMissing = false;

  const result = templateContent.replace(placeholderRegex, (match, varName) => {
    const value = envVars[varName];
    if (value === undefined) {
      console.warn(`Warning: Environment variable '${varName}' is not defined.`);
      hasMissing = true;
      return match; // keep the placeholder
    }
    return value;
  });

  if (hasMissing) {
    console.warn('Note: Some placeholders were not replaced because their environment variables were missing.');
  }

  fs.writeFileSync(outputPath, result, 'utf-8');
  console.log(`Successfully generated wrangler.toml at ${outputPath}`);
}

generate();
