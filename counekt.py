from app import create_app, db, geolocator, w3
import app.models as models

app = create_app()

@app.shell_context_processor
def make_shell_context():
    return {'db': db, "models": models, 'geolocator': geolocator, 'w3':w3}
