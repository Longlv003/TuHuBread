const { calculateDistanceKm } = require("./distance.util");

const BASE_FEE = 10000; // covers the first BASE_DISTANCE_KM
const BASE_DISTANCE_KM = 2;
const PER_KM_RATE = 4000; // charged for each km beyond BASE_DISTANCE_KM
const FALLBACK_DISTANCE_KM = 3; // used when the address has no coordinates yet

// Delivery option multiplies the distance-based fee instead of being a flat amount
const DELIVERY_MULTIPLIERS = {
  priority: 1.5,
  standard: 1.0,
  saving: 0.6
};

/**
 * Calculate the delivery fee for a single shop -> address leg based on real distance.
 * @param {[number, number]|undefined} shopCoordinates [lng, lat]
 * @param {[number, number]|undefined} addressCoordinates [lng, lat]
 * @param {string} deliveryOption "priority" | "standard" | "saving"
 */
function calculateDeliveryFee(shopCoordinates, addressCoordinates, deliveryOption) {
  const multiplier = DELIVERY_MULTIPLIERS[deliveryOption] ?? 1;

  const distanceKm = (shopCoordinates && addressCoordinates)
    ? calculateDistanceKm(shopCoordinates, addressCoordinates)
    : FALLBACK_DISTANCE_KM;

  const extraKm = Math.max(distanceKm - BASE_DISTANCE_KM, 0);
  const fee = (BASE_FEE + extraKm * PER_KM_RATE) * multiplier;

  return Math.round(fee / 1000) * 1000;
}

module.exports = { calculateDeliveryFee, DELIVERY_MULTIPLIERS };
