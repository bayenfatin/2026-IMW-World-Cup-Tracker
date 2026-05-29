const ADMIN_SESSION_KEY = 'imw-wc-admin-unlocked';

export function isAdminUnlocked() {
  return sessionStorage.getItem(ADMIN_SESSION_KEY) === 'true';
}

export function unlockAdmin() {
  sessionStorage.setItem(ADMIN_SESSION_KEY, 'true');
}

export function lockAdmin() {
  sessionStorage.removeItem(ADMIN_SESSION_KEY);
}

export function verifyAdminPin(pin, expectedPin) {
  return String(pin).trim() === String(expectedPin);
}

export function promptAdminPin(expectedPin) {
  const pin = window.prompt('Enter admin PIN to continue:');
  if (pin == null) return false;
  if (verifyAdminPin(pin, expectedPin)) {
    unlockAdmin();
    return true;
  }
  window.alert('Incorrect PIN.');
  return false;
}

export function requireAdmin(expectedPin) {
  if (isAdminUnlocked()) return true;
  return promptAdminPin(expectedPin);
}
