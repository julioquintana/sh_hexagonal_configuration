#!/bin/bash
log() {
  local level=$1
  local message=$2
  echo "[$level] $message"
}

# Solicitar BASE_PACKAGE
read -p "Ingresa el nombre del paquete base (por ejemplo, com.yourcompany.product): " BASE_PACKAGE

# Solicitar RESOURCE_NAME
read -p "Ingresa el nombre del recurso (por ejemplo, Producto): " RESOURCE_NAME

# Verificar si el directorio ya existe
if [ -d "src/main/java/$BASE_PACKAGE" ]; then
  echo "¡Atención! El directorio $BASE_PACKAGE ya existe."
  read -p "¿Quieres sobrescribir los archivos existentes? (S/n): " OVERWRITE
  if [ "$OVERWRITE" != "S" ] && [ "$OVERWRITE" != "s" ]; then
    echo "Operación cancelada."
    exit 1
  fi
fi

# Crear la estructura de directorios
mkdir -p src/main/java/$BASE_PACKAGE/$RESOURCE_NAME/application/usecase
mkdir -p src/main/java/$BASE_PACKAGE/$RESOURCE_NAME/application/service
mkdir -p src/main/java/$BASE_PACKAGE/$RESOURCE_NAME/domain/model
mkdir -p src/main/java/$BASE_PACKAGE/$RESOURCE_NAME/domain/port/in
mkdir -p src/main/java/$BASE_PACKAGE/$RESOURCE_NAME/domain/port/out
mkdir -p src/main/java/$BASE_PACKAGE/$RESOURCE_NAME/infrastructure/adapter/in
mkdir -p src/main/java/$BASE_PACKAGE/$RESOURCE_NAME/infrastructure/adapter/out
mkdir -p src/main/java/$BASE_PACKAGE/$RESOURCE_NAME/infrastructure/config
mkdir -p src/main/java/$BASE_PACKAGE/$RESOURCE_NAME/infrastructure/repository
mkdir -p src/main/java/$BASE_PACKAGE/$RESOURCE_NAME/infrastructure/utils


lowercase_first() {
  echo "$(tr '[:upper:]' '[:lower:]' <<< ${1:0:1})${1:1}"
}
uppercase() {
  echo "$1" | tr '[:lower:]' '[:upper:]'
}

# Función para crear archivos con implementaciones básicas
create_file() {
  local FILE_PATH=$1
  local CLASS_NAME=$2
  local PACKAGE_PATH=$3
  local IS_REPOSITORY=$4

  if [ -e "$FILE_PATH" ]; then
    read -p "¡Atención! El archivo $FILE_PATH ya existe. ¿Quieres sobrescribirlo? (S/n): " OVERWRITE_FILE
    if [ "$OVERWRITE_FILE" != "S" ] && [ "$OVERWRITE_FILE" != "s" ]; then
      echo "Operación cancelada para $FILE_PATH."
      return
    fi
  fi

  if [ "$IS_REPOSITORY" = true ]; then
    cat <<EOL > $FILE_PATH
package $BASE_PACKAGE.$RESOURCE_NAME.$PACKAGE_PATH;

import java.util.List;

public class $CLASS_NAME {
    // Implementación básica para repositorio
    public List<Object> getAll${CLASS_NAME}() {
        System.out.println("Recuperando todos los elementos desde el repositorio para $CLASS_NAME.");
        return null;
    }

    public void save${CLASS_NAME}(Object obj) {
        System.out.println("Guardando un elemento en el repositorio para $CLASS_NAME.");
    }
}
EOL
  else
    cat <<EOL > $FILE_PATH
package $BASE_PACKAGE.$RESOURCE_NAME.$PACKAGE_PATH;

import $BASE_PACKAGE.$RESOURCE_NAME.domain.port.in.*;

public class $CLASS_NAME implements ${CLASS_NAME}UseCase {
    // Implementación básica del caso de uso
    @Override
    public void execute() {
        System.out.println("$CLASS_NAME ejecutado con éxito.");
    }
}
EOL
  fi

  echo "Archivo $FILE_PATH creado con éxito."
}
create_use_case_file() {
  local FILE_PATH=$1
  local CLASS_NAME=$2
  local PACKAGE_PATH=$3
  local FILE_TYPE=$4
  local HAS_RESPONSE=$5
  local COLLECTION=$6

  if [ -e "$FILE_PATH" ]; then
    read -p "¡Atención! El archivo $FILE_PATH ya existe. ¿Quieres sobrescribirlo? (S/n): " OVERWRITE_FILE
    if [ "$OVERWRITE_FILE" != "S" ] && [ "$OVERWRITE_FILE" != "s" ]; then
      echo "Operación cancelada para $FILE_PATH."
      return
    fi
  fi

  if [ "$HAS_RESPONSE" = "t" ]; then
      RETURN_WORD="return"
    if [ "$COLLECTION" = "t" ]; then
        METHOD_RESPONSE="Flux<${RESOURCE_NAME}Dto>"
    else
        METHOD_RESPONSE="Mono<${RESOURCE_NAME}Dto>"
    fi
  else
    RETURN_WORD=""
    METHOD_RESPONSE="void"
  fi


  if [ "$FILE_TYPE" = "class" ]; then
    cat <<EOL > $FILE_PATH
package $BASE_PACKAGE.$RESOURCE_NAME.$PACKAGE_PATH;

import reactor.core.publisher.Flux;
import $BASE_PACKAGE.$RESOURCE_NAME.domain.port.in.${CLASS_NAME}UseCase;
import $BASE_PACKAGE.$RESOURCE_NAME.domain.model.${CLASS_NAME}Dto.java;
import $BASE_PACKAGE.$RESOURCE_NAME.domain.port.out.${CLASS_NAME}RepositoryPort.java;

public $FILE_TYPE ${CLASS_NAME}UseCaseImpl implements ${CLASS_NAME}UseCase {

    private final ${CLASS_NAME}RepositoryPort $(lowercase_first ${CLASS_NAME})RepositoryPort;

    @Override
    public $METHOD_RESPONSE $(lowercase_first ${CLASS_NAME})() {
        $RETURN_WORD $(lowercase_first ${CLASS_NAME})RepositoryPort.$(lowercase_first ${CLASS_NAME})();
    }
}
EOL
  else
    cat <<EOL > $FILE_PATH
package $BASE_PACKAGE.$RESOURCE_NAME.$PACKAGE_PATH;

import reactor.core.publisher.Flux;
import $BASE_PACKAGE.$RESOURCE_NAME.domain.model.${CLASS_NAME}Dto.java;

public $FILE_TYPE ${CLASS_NAME}UseCase {
    $METHOD_RESPONSE  $(lowercase_first ${CLASS_NAME})();
}
EOL
  fi


  echo "Archivo $FILE_PATH creado con éxito."
}

create_dto_file() {
  local FILE_PATH=$1
  local CLASS_NAME=$2
  local PACKAGE_PATH=$3
  local IS_ENTITY=$4

  if [ -e "$FILE_PATH" ]; then
    read -p "¡Atención! El archivo $FILE_PATH ya existe. ¿Quieres sobrescribirlo? (S/n): " OVERWRITE_FILE
    if [ "$OVERWRITE_FILE" != "S" ] && [ "$OVERWRITE_FILE" != "s" ]; then
      echo "Operación cancelada para $FILE_PATH."
      return
    fi
  fi

  if [ "$IS_ENTITY" = "false" ]; then
     CABECERA="
import java.util.List;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor"
    else
CABECERA="
import lombok.*;
import org.springframework.data.relational.core.mapping.Table;

@Data
@Builder
@ToString
@Generated
@NoArgsConstructor
@AllArgsConstructor
@Table(\"$(uppercase "$RESOURCE_NAME")\")"
  fi

    cat <<EOL > $FILE_PATH
package $BASE_PACKAGE.$RESOURCE_NAME.$PACKAGE_PATH;
$CABECERA
public class $CLASS_NAME {
    // atributos dto aqui

}
EOL
  echo "Archivo $FILE_PATH creado con éxito."
}

create_service_file(){
  local SERVICE_FILE=$1
  local CLASS_NAME=$2
  local PACKAGE_PATH=$3
  local RESPONSES=("${@:4}")

  if [ -e "$SERVICE_FILE" ]; then
    read -p "¡Atención! El archivo $SERVICE_FILE ya existe. ¿Quieres sobrescribirlo? (S/n): " OVERWRITE_SERVICE
    if [ "$OVERWRITE_SERVICE" != "S" ] && [ "$OVERWRITE_SERVICE" != "s" ]; then
      echo "Operación cancelada para $SERVICE_FILE."
      exit 1
    fi
  fi

  cat <<EOL > $SERVICE_FILE
package $BASE_PACKAGE.$RESOURCE_NAME.$PACKAGE_PATH;

import $BASE_PACKAGE.$RESOURCE_NAME.domain.port.in.*;
import lombok.AllArgsConstructor;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@AllArgsConstructor
public class ${CLASS_NAME} {
// Implementación de todos los casos de uso
EOL

  USE_CASE_SUXFIX="UseCase"  # Puedes personalizar esto según tu necesidad
  for RESPONSE in "${RESPONSES[@]}"; do
    IFS='|' read -r HAS_RESPONSE COLLECTION USE_CASE <<< "$RESPONSE"

    log "INFO" "VALOR DE RESPUESTAS: $RESPONSE"

    if [ "$HAS_RESPONSE" = "true" ]; then
      RETURN_WORD="return"
      if [ "$COLLECTION" = "true" ]; then
        METHOD_RESPONSE="Flux<${RESOURCE_NAME}Dto>"
      else
        METHOD_RESPONSE="Mono<${RESOURCE_NAME}Dto>"
      fi
    else
      RETURN_WORD=""
      METHOD_RESPONSE="void"
    fi

    LOWERCASE_USE_CASE=$(lowercase_first $USE_CASE)

    echo "    private final ${USE_CASE}${USE_CASE_SUXFIX} ${LOWERCASE_USE_CASE}${USE_CASE_SUXFIX};" >> $SERVICE_FILE
  done

  for RESPONSE in "${RESPONSES[@]}"; do
    IFS='|' read -r HAS_RESPONSE COLLECTION USE_CASE <<< "$RESPONSE"
        if [ "$HAS_RESPONSE" = "true" ]; then
          RETURN_WORD="return"
          if [ "$COLLECTION" = "true" ]; then
            METHOD_RESPONSE="Flux<${RESOURCE_NAME}Dto>"
          else
            METHOD_RESPONSE="Mono<${RESOURCE_NAME}Dto>"
          fi
        else
          RETURN_WORD=""
          METHOD_RESPONSE="void"
        fi

LOWERCASE_USE_CASE=$(lowercase_first $USE_CASE)

    echo "    public $METHOD_RESPONSE ${LOWERCASE_USE_CASE}() {" >> $SERVICE_FILE
    echo "        ${LOWERCASE_USE_CASE}${USE_CASE_SUXFIX}.${LOWERCASE_USE_CASE}();" >> $SERVICE_FILE
    echo "    }" >> $SERVICE_FILE
  done

  cat <<EOL >> $SERVICE_FILE
  }
EOL

  echo "Archivo $SERVICE_FILE creado con éxito."
}

create_service_repository_interface_file(){
  local SERVICE_FILE=$1
  local CLASS_NAME=$2
  local PACKAGE_PATH=$3
  local RESPONSES=("${@:4}")

  if [ -e "$SERVICE_FILE" ]; then
    read -p "¡Atención! El archivo $SERVICE_FILE ya existe. ¿Quieres sobrescribirlo? (S/n): " OVERWRITE_SERVICE
    if [ "$OVERWRITE_SERVICE" != "S" ] && [ "$OVERWRITE_SERVICE" != "s" ]; then
      echo "Operación cancelada para $SERVICE_FILE."
      exit 1
    fi
  fi

  cat <<EOL > $SERVICE_FILE
package $BASE_PACKAGE.$RESOURCE_NAME.$PACKAGE_PATH;

import $BASE_PACKAGE.$RESOURCE_NAME.domain.port.in.*;
import $BASE_PACKAGE.$RESOURCE_NAME.domain.model.${RESOURCE_NAME}Dto.java;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

public interface ${CLASS_NAME} {
EOL

  for RESPONSE in "${RESPONSES[@]}"; do
    IFS='|' read -r HAS_RESPONSE COLLECTION USE_CASE <<< "$RESPONSE"
        if [ "$HAS_RESPONSE" = "true" ]; then
          RETURN_WORD="return"
          if [ "$COLLECTION" = "true" ]; then
            METHOD_RESPONSE="Flux<${RESOURCE_NAME}Dto>"
          else
            METHOD_RESPONSE="Mono<${RESOURCE_NAME}Dto>"
          fi
        else
          RETURN_WORD=""
          METHOD_RESPONSE="void"
        fi

LOWERCASE_USE_CASE=$(lowercase_first $USE_CASE)

    echo "    $METHOD_RESPONSE ${LOWERCASE_USE_CASE}();" >> $SERVICE_FILE
  done

  cat <<EOL >> $SERVICE_FILE
  }
EOL

  echo "Archivo $SERVICE_FILE creado con éxito."
}

# Crear DTO en domain/model
create_dto_file "src/main/java/$BASE_PACKAGE/$RESOURCE_NAME/domain/model/${RESOURCE_NAME}Dto.java" "${RESOURCE_NAME}Dto" "domain.model" "false"

# Crear archivos de ejemplo para cada caso de uso
read -p "Ingresa los casos de uso separados por espacios (por ejemplo, CasoUso1 CasoUso2): " USE_CASES
for USE_CASE in $USE_CASES; do
  read -p "¿$USE_CASE Tiene Respuesta? (true/false): " HAS_RESPONSE
  if [ "$HAS_RESPONSE" = "true" ]; then
    read -p "¿la respuesta de $USE_CASE es una Coleccion? (true/false): " COLLECTION
  fi

  RESPONSES+=("$HAS_RESPONSE|$COLLECTION|$USE_CASE")

  create_use_case_file "src/main/java/$BASE_PACKAGE/$RESOURCE_NAME/application/usecase/${USE_CASE}UseCaseImpl.java" "${USE_CASE}" "application.usecase" "class" "$HAS_RESPONSE" "$COLLECTION"
# Crear interfaces en domain/port/in para cada caso de uso
  create_use_case_file "src/main/java/$BASE_PACKAGE/$RESOURCE_NAME/domain/port/in/${USE_CASE}UseCase.java" "${USE_CASE}UseCase" "domain.port.in" "interface" "$HAS_RESPONSE" "$COLLECTION"
done

# Crear archivo de implementación de repositorio en infrastructure/repository
create_use_case_file "src/main/java/$BASE_PACKAGE/$RESOURCE_NAME/infrastructure/adapter/out/RepositoryAdapter.java" "RepositoryAdapter" "infrastructure.adapter.out" "class"

# Crear la interfaz de repositorio en domain/port/out
create_service_repository_interface_file "src/main/java/$BASE_PACKAGE/$RESOURCE_NAME/domain/port/out/${RESOURCE_NAME}RepositoryPort.java" "${RESOURCE_NAME}RepositoryPort" "domain.port.out" "${RESPONSES[@]}"

# Crear archivos de servicio
create_service_file "src/main/java/$BASE_PACKAGE/$RESOURCE_NAME/application/service/${RESOURCE_NAME}Service.java" "${RESOURCE_NAME}Service" "application.service" "${RESPONSES[@]}"


echo "Estructura de paquetes y archivos creada exitosamente."