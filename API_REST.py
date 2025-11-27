from flask import Flask, jsonify, request
from flask_jwt_extended import create_access_token, jwt_required, JWTManager
import pyodbc 
from datetime import timedelta

app = Flask(__name__)

app.config["JWT_SECRET_KEY"] = "clave-super-secreta-para-apt29-simulacion" # ¡CAMBIAR EN PRODUCCIÓN!
app.config["JWT_ACCESS_TOKEN_EXPIRES"] = timedelta(hours=1)
jwt = JWTManager(app)

SERVER_NAME = 'WIN-IG5U6V6SUTN\SQLEXPRESS02'
DATABASE_NAME = 'HistoriasMedicas'

app.config['SQLALCHEMY_DATABASE_URI'] = f'mssql+pyodbc:///?odbc_connect=DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={SERVER_NAME};DATABASE={DATABASE_NAME};Trusted_Connection=yes;'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

HISTORIALES_DB = {
    101: {"id": 101, "paciente": "Ana Pérez", "diagnostico": "APENDICITIS AGUDA", "info_sensible": "Riesgo de fuga"},
    202: {"id": 202, "paciente": "Beto Gómez", "diagnostico": "NEUMONÍA BACTERIANA", "info_sensible": "Contrato 002"},
    303: {"id": 303, "paciente": "Carlos Díaz", "diagnostico": "MIGRAÑA CRÓNICA", "info_sensible": "Cuenta Bancaria"}
}
USUARIOS = {
    "doctor": "password123",
    "admin": "adminsecure"
}


@app.route('/api/login', methods=['POST'])
def login():
    """Endpoint para autenticar al usuario y emitir un token JWT."""
    data = request.get_json()
    username = data.get('username', None)
    password = data.get('password', None)

    if username in USUARIOS and USUARIOS[username] == password:
        access_token = create_access_token(identity=username)
        return jsonify(access_token=access_token), 200
    
    return jsonify({"msg": "Credenciales inválidas"}), 401

@app.route('/api/historiales/<int:paciente_id>', methods=['GET'])
@jwt_required() 
def get_historial(paciente_id):
    """Endpoint vulnerable (simulado) para acceder a historial por ID."""

    historial = HISTORIALES_DB.get(paciente_id)

    if historial:
        return jsonify({
            "id": historial["id"],
            "paciente": historial["paciente"],
            "diagnostico": historial["diagnostico"],
            "data_extra": historial["info_sensible"]
        }), 200
    
    return jsonify({"msg": "Historial no encontrado"}), 404


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)