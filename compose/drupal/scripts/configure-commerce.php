<?php

/**
 * @file
 * Configure Drupal Commerce pour la demonstration CR465.
 *
 * Execute avec : drush php:script /tmp/configure-commerce.php
 * Idempotent : relancer ne cree pas de doublon.
 */

use Drupal\commerce_product\Entity\Product;
use Drupal\commerce_product\Entity\ProductVariation;
use Drupal\commerce_payment\Entity\PaymentGateway;

$etm = \Drupal::entityTypeManager();

// --- 1. Boutique par defaut -----------------------------------------
$stores = $etm->getStorage('commerce_store')->loadMultiple();
if (empty($stores)) {
  throw new \RuntimeException('Aucune boutique : activer commerce_store d abord.');
}
$store = reset($stores);
print "Boutique : {$store->getName()} ({$store->id()})\n";

// --- 2. Passerelle de paiement simulee ------------------------------
$gateway = $etm->getStorage('commerce_payment_gateway')->load('cr465_example');
if (!$gateway) {
  $gateway = PaymentGateway::create([
    'id' => 'cr465_example',
    'label' => 'Paiement simule (demonstration)',
    'plugin' => 'example_onsite',
    'configuration' => [
      'display_label' => 'Paiement simule',
      'mode' => 'test',
      'instructions' => [
        'value' => 'Aucun paiement reel : ce mode existe uniquement pour la demonstration CR465.',
        'format' => 'plain_text',
      ],
    ],
    'weight' => 0,
  ]);
  $gateway->save();
  print "Passerelle creee : {$gateway->id()}\n";
}
else {
  print "Passerelle deja presente : {$gateway->id()}\n";
}

// --- 3. Produit de formation ----------------------------------------
$storage = $etm->getStorage('commerce_product');
$existing = $storage->loadByProperties(['title' => 'Formation CR465 - Initiation aux conteneurs']);
if ($existing) {
  $product = reset($existing);
  print "Produit deja present : {$product->id()}\n";
}
else {
  $variation = ProductVariation::create([
    'type' => 'default',
    'sku' => 'CR465-FORM-01',
    'title' => 'Formation CR465 - Initiation aux conteneurs',
    'price' => new \Drupal\commerce_price\Price('49.00', 'USD'),
    'status' => 1,
  ]);
  $variation->save();

  $product = Product::create([
    'type' => 'default',
    'title' => 'Formation CR465 - Initiation aux conteneurs',
    'body' => [
      'value' => 'Formation en ligne : technologies et securite des conteneurs. Acces immediat apres achat.',
      'format' => 'basic_html',
    ],
    'status' => 1,
    'stores' => [$store->id()],
    'variations' => [$variation],
  ]);
  $product->save();
  print "Produit cree : {$product->id()} (SKU CR465-FORM-01)\n";
}

// --- 4. URL du site et domaines de confiance ------------------------
$config = \Drupal::configFactory()->getEditable('system.site');
print "Site : {$config->get('name')} / page d accueil : {$config->get('page.front')}\n";

print "Termine.\n";
