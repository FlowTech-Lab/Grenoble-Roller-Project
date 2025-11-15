#!/usr/bin/env node

const lighthouse = require('lighthouse');
const chromeLauncher = require('chrome-launcher');
const fs = require('fs');
const path = require('path');

const BASE_URL = process.env.BASE_URL || 'http://localhost:3000';
const OUTPUT_DIR = path.join(__dirname, '../docs/08-security-privacy/a11y-reports');
const TIMESTAMP = new Date().toISOString().replace(/[:.]/g, '-').slice(0, -5);

const urls = [
  { url: BASE_URL, name: 'Homepage' },
  { url: `${BASE_URL}/association`, name: 'Association' },
  { url: `${BASE_URL}/shop`, name: 'Boutique' },
  { url: `${BASE_URL}/events`, name: 'Événements' },
  { url: `${BASE_URL}/users/sign_in`, name: 'Connexion' },
  { url: `${BASE_URL}/users/sign_up`, name: 'Inscription' },
];

async function runLighthouse(url, name) {
  console.log(`\n🔍 Test Lighthouse: ${name} (${url})`);
  
  const chrome = await chromeLauncher.launch({ chromeFlags: ['--headless'] });
  const options = {
    logLevel: 'info',
    output: 'json',
    onlyCategories: ['accessibility'],
    port: chrome.port,
  };

  try {
    const runnerResult = await lighthouse(url, options);
    const report = runnerResult.report;
    
    // Sauvegarder le rapport JSON
    const filename = `lighthouse-${name.toLowerCase().replace(/\s+/g, '-')}-${TIMESTAMP}.json`;
    const filepath = path.join(OUTPUT_DIR, filename);
    fs.writeFileSync(filepath, report);
    
    // Afficher le score
    const lhr = JSON.parse(report);
    const score = Math.round(lhr.categories.accessibility.score * 100);
    console.log(`  ✅ Score accessibilité: ${score}/100`);
    
    if (score < 90) {
      console.log(`  ⚠️  Score en dessous de 90/100`);
    }
    
    await chrome.kill();
    return { name, url, score, filepath };
  } catch (error) {
    console.error(`  ❌ Erreur: ${error.message}`);
    await chrome.kill();
    return { name, url, score: 0, error: error.message };
  }
}

async function main() {
  if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  }

  console.log('🚀 Démarrage des tests Lighthouse');
  console.log(`Base URL: ${BASE_URL}`);
  console.log(`Output: ${OUTPUT_DIR}\n`);

  const results = [];
  
  for (const { url, name } of urls) {
    const result = await runLighthouse(url, name);
    results.push(result);
  }

  // Résumé
  console.log('\n========================================');
  console.log('RÉSUMÉ DES TESTS LIGHTHOUSE');
  console.log('========================================\n');
  
  results.forEach(({ name, score, error }) => {
    if (error) {
      console.log(`❌ ${name}: Erreur - ${error}`);
    } else {
      const status = score >= 90 ? '✅' : score >= 80 ? '⚠️' : '❌';
      console.log(`${status} ${name}: ${score}/100`);
    }
  });
  
  const avgScore = results
    .filter(r => !r.error)
    .reduce((sum, r) => sum + r.score, 0) / results.filter(r => !r.error).length;
  
  console.log(`\n📊 Score moyen: ${Math.round(avgScore)}/100`);
  console.log(`\n📁 Rapports sauvegardés dans: ${OUTPUT_DIR}`);
}

main().catch(console.error);
