from app import create_app, db, geolocator, w3, etherscan
import app.models as models
import app.funcs as funcs

app = create_app()

@app.shell_context_processor
def make_shell_context():
    return {'db': db, "models": models, 'geolocator': geolocator, 'w3':w3, 'etherscan':etherscan, 'funcs':funcs}

# Entrepreneurial infrastructure for the internet.