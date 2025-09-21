# Simple Webhook Receiver for Gatus Deployment
# Alternative to GitHub Actions - lightweight webhook endpoint

import os
import subprocess
import hmac
import hashlib
from flask import Flask, request, jsonify

app = Flask(__name__)

# GitHub webhook secret (set in environment)
WEBHOOK_SECRET = os.environ.get('GITHUB_WEBHOOK_SECRET', '')
DEPLOY_SCRIPT = '/opt/scripts/deploy-gatus.sh'

def verify_signature(payload_body, signature_header):
    """Verify GitHub webhook signature"""
    if not signature_header:
        return False
    
    sha_name, signature = signature_header.split('=')
    if sha_name != 'sha256':
        return False
    
    mac = hmac.new(WEBHOOK_SECRET.encode(), payload_body, hashlib.sha256)
    return hmac.compare_digest(mac.hexdigest(), signature)

@app.route('/webhook/gatus', methods=['POST'])
def deploy_webhook():
    """Handle GitHub webhook for Gatus deployment"""
    
    # Verify webhook signature
    signature = request.headers.get('X-Hub-Signature-256')
    if not verify_signature(request.data, signature):
        return jsonify({'error': 'Invalid signature'}), 403
    
    # Check if this is a push to main branch
    payload = request.json
    if payload.get('ref') != 'refs/heads/main':
        return jsonify({'message': 'Not main branch, ignoring'}), 200
    
    try:
        # Run deployment script
        result = subprocess.run(['/bin/bash', DEPLOY_SCRIPT], 
                              capture_output=True, text=True, timeout=300)
        
        if result.returncode == 0:
            return jsonify({
                'status': 'success',
                'message': 'Deployment completed successfully',
                'output': result.stdout
            }), 200
        else:
            return jsonify({
                'status': 'error',
                'message': 'Deployment failed',
                'error': result.stderr
            }), 500
            
    except subprocess.TimeoutExpired:
        return jsonify({
            'status': 'error',
            'message': 'Deployment timed out'
        }), 500
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': f'Deployment error: {str(e)}'
        }), 500

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({'status': 'healthy'}), 200

if __name__ == '__main__':
    # Run on port 5000, only accessible locally
    app.run(host='127.0.0.1', port=5000, debug=False)