/**
 * FCM Service - Handles Firebase Cloud Messaging interactions.
 * Does not include MongoDB logic to respect Single Responsibility Principle.
 */

const { messaging } = require("../configs/firebase.config");

class FcmService {
  /**
   * Send notification to a single token
   * @param {Object} params
   * @param {string} params.token - Target device FCM token
   * @param {Object} params.notification - { title, body }
   * @param {Object} [params.data] - Key-value payload (all values must be strings)
   * @returns {Promise<{ success: boolean, error?: Error }>}
   */
  async sendToToken({ token, notification, data = {} }) {
    try {
      // Ensure all data values are strings as required by Firebase
      const stringifiedData = {};
      if (data) {
        for (const [key, value] of Object.entries(data)) {
          stringifiedData[key] = value !== null && value !== undefined ? String(value) : "";
        }
      }

      const message = {
        token,
        notification: {
          title: notification.title,
          body: notification.body || notification.message,
        },
        data: stringifiedData,
      };

      const response = await messaging.send(message);
      return { success: true, messageId: response };
    } catch (error) {
      console.error(`[FCMService] Failed to send to token: ${token.substring(0, 15)}...`, error.message);
      
      // Determine if token is invalid or expired
      const isInvalid = this._isInvalidTokenError(error);
      return { success: false, error, isTokenInvalid: isInvalid };
    }
  }

  /**
   * Send notification to multiple tokens
   * @param {Object} params
   * @param {string[]} params.tokens - Array of target device FCM tokens
   * @param {Object} params.notification - { title, body }
   * @param {Object} [params.data] - Key-value payload (all values must be strings)
   * @returns {Promise<{ successCount: number, failureCount: number, invalidTokens: string[] }>}
   */
  async sendToMultipleTokens({ tokens, notification, data = {} }) {
    if (!Array.isArray(tokens) || tokens.length === 0) {
      return { successCount: 0, failureCount: 0, invalidTokens: [] };
    }

    const stringifiedData = {};
    if (data) {
      for (const [key, value] of Object.entries(data)) {
        stringifiedData[key] = value !== null && value !== undefined ? String(value) : "";
      }
    }

    const messages = tokens.map(token => ({
      token,
      notification: {
        title: notification.title,
        body: notification.body || notification.message,
      },
      data: stringifiedData,
    }));

    try {
      const response = await messaging.sendEach(messages);
      const invalidTokens = [];
      let successCount = 0;
      let failureCount = 0;

      response.responses.forEach((res, index) => {
        if (res.success) {
          successCount++;
        } else {
          failureCount++;
          const token = tokens[index];
          console.error(`[FCMService] Send failed for token: ${token.substring(0, 15)}... Error:`, res.error?.message);
          if (this._isInvalidTokenError(res.error)) {
            invalidTokens.push(token);
          }
        }
      });

      return {
        successCount,
        failureCount,
        invalidTokens,
      };
    } catch (error) {
      console.error("[FCMService] Batch send failed completely", error.message);
      // Fallback: Try sending individually to not block the request
      const invalidTokens = [];
      let successCount = 0;
      let failureCount = 0;

      for (const token of tokens) {
        const result = await this.sendToToken({ token, notification, data });
        if (result.success) {
          successCount++;
        } else {
          failureCount++;
          if (result.isTokenInvalid) {
            invalidTokens.push(token);
          }
        }
      }

      return {
        successCount,
        failureCount,
        invalidTokens,
      };
    }
  }

  /**
   * Check if the error code from Firebase indicates an invalid/expired token
   * @private
   */
  _isInvalidTokenError(error) {
    if (!error) return false;
    const errorCode = error.code;
    const errorMessage = error.message || "";
    
    // Firebase standard error codes for invalid registration tokens
    return (
      errorCode === "messaging/invalid-argument" ||
      errorCode === "messaging/invalid-registration-token" ||
      errorCode === "messaging/registration-token-not-registered" ||
      errorMessage.includes("Requested entity was not found") ||
      errorMessage.includes("registration token is not registered") ||
      errorMessage.includes("invalid-registration-token")
    );
  }
}

module.exports = new FcmService();
