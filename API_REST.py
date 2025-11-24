from flask import Flask, jsonify, request
from flask_jwt_extended import create_access_token, jwt_required, JWTManager
import pyodbc # Necesario para la conexión real a SQL Server
from datetime import timedelta

# --- CONFIGURACIÓN DE LA APLICACIÓN ---
app = Flask(__name__)

# Configuración JWT (Clave Secreta y Tiempo de Expiración)
app.config["JWT_SECRET_KEY"] = "clave-super-secreta-para-apt29-simulacion" # ¡CAMBIAR EN PRODUCCIÓN!
app.config["JWT_ACCESS_TOKEN_EXPIRES"] = timedelta(hours=1)
jwt = JWTManager(app)

# Configuración de Conexión a SQL Server (Cadena Ficticia)
# Asegúrate de que el driver 'ODBC Driver 17 for SQL Server' esté instalado.
SERVER_NAME = 'WIN-IG5U6V6SUTN\SQLEXPRESS02'  # Ej: WIN-SERVER2019\SQLEXPRESS
DATABASE_NAME = 'HistoriasMedicas'

# Cadena de Conexión ODBC con Autenticación de Windows
# Si usas SQL Authentication, la cadena es diferente (UID y PWD)
app.config['SQLALCHEMY_DATABASE_URI'] = f'mssql+pyodbc:///?odbc_connect=DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={SERVER_NAME};DATABASE={DATABASE_NAME};Trusted_Connection=yes;'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# --- SIMULACIÓN DE DATOS Y CONEXIÓN ---

# **ATENCIÓN:** Esto es un DUMMY para simular datos sensibles.
# En una implementación real, usarías SQLAlchemy para ORM y consultas.
HISTORIALES_DB = {
    101: {"id": 101, "paciente": "Ana Pérez", "diagnostico": "APENDICITIS AGUDA", "info_sensible": "Riesgo de fuga"},
    202: {"id": 202, "paciente": "Beto Gómez", "diagnostico": "NEUMONÍA BACTERIANA", "info_sensible": "Contrato 002"},
    303: {"id": 303, "paciente": "Carlos Díaz", "diagnostico": "MIGRAÑA CRÓNICA", "info_sensible": "Cuenta Bancaria"}
}
USUARIOS = {
    "doctor": "password123", # Credencial de prueba a revocar tras el ataque
    "admin": "adminsecure"
}


# --- ENDPOINTS DE LA API ---

@app.route('/api/login', methods=['POST'])
def login():
    """Endpoint para autenticar al usuario y emitir un token JWT."""
    data = request.get_json()
    username = data.get('username', None)
    password = data.get('password', None)

    if username in USUARIOS and USUARIOS[username] == password:
        # Crea el token de acceso JWT para el usuario
        access_token = create_access_token(identity=username)
        return jsonify(access_token=access_token), 200
    
    return jsonify({"msg": "Credenciales inválidas"}), 401

@app.route('/api/historiales/<int:paciente_id>', methods=['GET'])
@jwt_required() # Requiere un token JWT válido
def get_historial(paciente_id):
    """Endpoint vulnerable (simulado) para acceder a historial por ID."""
    
    # SIMULACIÓN DE VULNERABILIDAD IDOR (Insecure Direct Object Reference)
    # y acceso a datos sensibles.
    historial = HISTORIALES_DB.get(paciente_id)

    if historial:
        # Devuelve datos sensibles
        return jsonify({
            "id": historial["id"],
            "paciente": historial["paciente"],
            "diagnostico": historial["diagnostico"],
            "data_extra": historial["info_sensible"] # Datos críticos para simular exfiltración
        }), 200
    
    return jsonify({"msg": "Historial no encontrado"}), 404

# --- INICIO DE LA APLICACIÓN ---

if __name__ == '__main__':
    # Usaremos el puerto 5000 para pruebas locales antes de configurarlo en IIS
    app.run(host='0.0.0.0', port=5000)