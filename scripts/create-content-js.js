const fs = require('fs');

['nda', 'partner', 'distributor'].forEach(t => {
  const jsonPath = 'lib/templates/' + t + '/content.json';
  const jsPath = 'lib/templates/' + t + '/content.js';
  const data = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
  const jsContent = 'const content = ' + JSON.stringify(data, null, 2) + ';\nexport default content;\n';
  fs.writeFileSync(jsPath, jsContent, 'utf8');
  console.log('Created ' + jsPath);
});
