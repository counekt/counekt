
class Event(db.Model, Base):
    id = db.Column(db.Integer, primary_key=True)
    entity_id = db.Column(db.Integer, db.ForeignKey('idea.id', ondelete='CASCADE'))
    timestamp = db.Column(db.Integer)
    payload_json = db.Column(db.Text)

