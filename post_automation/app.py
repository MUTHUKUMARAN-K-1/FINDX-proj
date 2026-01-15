from flask import Flask, request, jsonify
from flask_cors import CORS
import os
from dotenv import load_dotenv
import requests

load_dotenv()

app = Flask(__name__)
CORS(app)

# Instagram Graph API settings
ACCESS_TOKEN = os.getenv('ACCESS_TOKEN')
IG_USER_ID = os.getenv('IG_USER_ID')
API_VERSION = os.getenv('API_VERSION', 'v17.0')
GRAPH_HOST = os.getenv('GRAPH_HOST', 'graph.instagram.com')

@app.route('/')
def health():
    return jsonify({
        'status': 'ok',
        'service': 'FindX Instagram API',
        'version': '1.0.0'
    })

@app.route('/api/post', methods=['POST'])
def post_to_instagram():
    """
    Post an image to Instagram
    Body: { "image_url": "https://...", "caption": "..." }
    """
    if not ACCESS_TOKEN or not IG_USER_ID:
        return jsonify({'error': 'Instagram credentials not configured'}), 500
    
    data = request.json
    image_url = data.get('image_url')
    caption = data.get('caption', '')
    
    if not image_url:
        return jsonify({'error': 'image_url is required'}), 400
    
    try:
        # Step 1: Create media container
        container_url = f'https://{GRAPH_HOST}/{API_VERSION}/{IG_USER_ID}/media'
        container_response = requests.post(container_url, data={
            'image_url': image_url,
            'caption': caption,
            'access_token': ACCESS_TOKEN
        })
        container_data = container_response.json()
        
        if 'id' not in container_data:
            return jsonify({'error': 'Failed to create container', 'details': container_data}), 400
        
        container_id = container_data['id']
        
        # Step 2: Publish the container
        publish_url = f'https://{GRAPH_HOST}/{API_VERSION}/{IG_USER_ID}/media_publish'
        publish_response = requests.post(publish_url, data={
            'creation_id': container_id,
            'access_token': ACCESS_TOKEN
        })
        publish_data = publish_response.json()
        
        if 'id' not in publish_data:
            return jsonify({'error': 'Failed to publish', 'details': publish_data}), 400
        
        return jsonify({
            'success': True,
            'post_id': publish_data['id'],
            'message': 'Posted to Instagram successfully!'
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/status')
def status():
    """Check if Instagram is configured"""
    return jsonify({
        'configured': bool(ACCESS_TOKEN and IG_USER_ID),
        'api_version': API_VERSION
    })

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
