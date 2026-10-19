<?php

/**
 * @file
 * Simule un achat complet pour la demonstration CR465.
 *
 * Cree une commande pour l'email fourni, l'ajoute au panier, la marque
 * "completed" (paiement simule) : le module cr465_notify appelle alors
 * n8n, qui inscrit l'apprenant dans Moodle.
 *
 * Usage : drush php:script /tmp/simulate-purchase.php etudiant1@cr465.test
 */

use Drupal\commerce_order\Entity\Order;
use Drupal\commerce_order\Entity\OrderItem;

$email = $extra[0] ?? 'etudiant1@cr465.test';
$etm = \Drupal::entityTypeManager();

$stores = $etm->getStorage('commerce_store')->loadMultiple();
$store = reset($stores);

$variations = $etm->getStorage('commerce_product_variation')->loadByProperties(['sku' => 'CR465-FORM-01']);
$variation = reset($variations);
if (!$variation) {
  throw new \RuntimeException('Variation CR465-FORM-01 introuvable.');
}

// Commande + ligne de commande
$order = Order::create([
  'type' => 'default',
  'store_id' => $store->id(),
  'uid' => 0,
  'mail' => $email,
  'placed' => \Drupal::time()->getRequestTime(),
]);
$order->save();

$item = OrderItem::create([
  'type' => 'default',
  'purchased_entity' => $variation->id(),
  'quantity' => 1,
  'unit_price' => $variation->getPrice(),
]);
$item->save();
$order->addItem($item);
$order->save();
print "Commande {$order->id()} creee pour {$email} — total " . $order->getTotalPrice()->getNumber() . " " . $order->getTotalPrice()->getCurrencyCode() . "\n";

// Paiement simule : passage direct a l'etat "completed"
$order->set('state', 'completed');
$order->save();
print "Commande {$order->id()} marquee completed — le webhook n8n est declenche.\n";
