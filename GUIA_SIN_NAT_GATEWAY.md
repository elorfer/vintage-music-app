# 💰 Guía: Usar Subnets Públicas SIN NAT Gateway para Ahorrar Costos

## 📋 Resumen

Esta guía explica cómo configurar tu infraestructura ECS para usar **subnets públicas con IPs públicas** en lugar de NAT Gateway, ahorrando **~$32/mes**.

---

## ✅ Ventajas

- ✅ **Ahorro**: ~$32/mes (sin NAT Gateway)
- ✅ **Rendimiento**: Sin punto único de fallo
- ✅ **Simplicidad**: Configuración más directa

## ⚠️ Consideraciones de Seguridad

- ⚠️ Las tareas ECS tendrán IPs públicas
- ⚠️ **Mitigación**: Usa Security Groups estrictos (solo permitir tráfico del ALB)
- ⚠️ **Mitigación**: Tu app ya está detrás de un ALB que filtra el tráfico

---

## 🔧 Pasos para Configurar

### Paso 1: Verificar Internet Gateway

Ya tienes un Internet Gateway configurado:
- **IGW ID**: `igw-0c06b74b30c5e4888`
- **Estado**: `available`

### Paso 2: Hacer Subnets Públicas (Opcional)

Si quieres que las subnets asignen IPs públicas automáticamente:

```bash
# Modificar subnets existentes para asignar IPs públicas
aws ec2 modify-subnet-attribute --subnet-id subnet-0749c393dceeada5c --map-public-ip-on-launch
aws ec2 modify-subnet-attribute --subnet-id subnet-0afad41238df3d96d --map-public-ip-on-launch
```

**Nota**: Esto no es necesario si usas `assignPublicIp: ENABLED` en ECS.

### Paso 3: Asegurar Rutas al Internet Gateway

Verifica que tus route tables tengan rutas al IGW:

```bash
# Ver rutas actuales
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=vpc-0c6e191050cee9035" \
  --query 'RouteTables[*].[RouteTableId,Routes[?GatewayId!=null]]' --output table
```

Si no hay ruta `0.0.0.0/0 -> igw-xxx`, créala:

```bash
# Agregar ruta al Internet Gateway (para las subnets que usarás)
aws ec2 create-route --route-table-id rtb-XXX --destination-cidr-block 0.0.0.0/0 --gateway-id igw-0c06b74b30c5e4888
```

### Paso 4: Actualizar Servicio ECS

Actualiza tu servicio ECS para usar IPs públicas:

```bash
aws ecs update-service \
  --cluster backend-prod-cluster \
  --service vintage-music-backend-service \
  --network-configuration "awsvpcConfiguration={
    subnets=[subnet-0749c393dceeada5c,subnet-0afad41238df3d96d],
    securityGroups=[sg-XXX],
    assignPublicIp=ENABLED
  }" \
  --force-new-deployment
```

### Paso 5: Verificar Security Groups

**IMPORTANTE**: Asegúrate de que tus Security Groups solo permitan:
- ✅ Tráfico del ALB (puerto 3000 desde el security group del ALB)
- ✅ NO permitas tráfico directo desde internet a las tareas ECS

```bash
# Ver security groups del servicio ECS
aws ecs describe-services --cluster backend-prod-cluster \
  --services vintage-music-backend-service \
  --query 'services[0].networkConfiguration.awsvpcConfiguration.securityGroups' \
  --output table

# Verificar reglas del security group
aws ec2 describe-security-groups --group-ids sg-XXX \
  --query 'SecurityGroups[0].{GroupId:GroupId,IpPermissions:IpPermissions}' \
  --output json
```

---

## 🔄 Cambios en el Código (Opcional)

Si estás usando CloudFormation o Terraform, actualiza:

### CloudFormation/Terraform

```yaml
# En tu task definition o service
NetworkConfiguration:
  AwsvpcConfiguration:
    Subnets:
      - subnet-0749c393dceeada5c
      - subnet-0afad41238df3d96d
    SecurityGroups:
      - sg-XXX
    AssignPublicIp: ENABLED  # ← Clave para ahorrar sin NAT Gateway
```

---

## ✅ Verificación

Después de actualizar, verifica:

```bash
# 1. Ver que el servicio está usando IPs públicas
aws ecs describe-tasks --cluster backend-prod-cluster \
  --tasks $(aws ecs list-tasks --cluster backend-prod-cluster --service-name vintage-music-backend-service --query 'taskArns[0]' --output text) \
  --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' \
  --output text | xargs -I {} aws ec2 describe-network-interfaces \
  --network-interface-ids {} \
  --query 'NetworkInterfaces[0].Association.PublicIp' \
  --output text

# 2. Verificar que las tareas pueden acceder a internet (desde dentro del contenedor)
# Ejecuta un contenedor de prueba y prueba: curl https://api.stripe.com
```

---

## 💰 Ahorro Estimado

- **NAT Gateway eliminado**: ~$32/mes
- **Costo adicional**: $0 (IPs públicas son gratuitas)
- **Total ahorrado**: ~$32/mes (~$1/día)

---

## 🔒 Seguridad: Best Practices

1. **Security Groups estrictos**:
   - Solo permitir tráfico del ALB
   - No exponer puertos directamente a internet

2. **Usar ALB** (ya lo tienes):
   - El ALB filtra el tráfico
   - Las tareas ECS no reciben tráfico directo de internet

3. **No exponer la base de datos**:
   - RDS sigue en subnets privadas ✅
   - Solo ECS usa subnets públicas

---

## 🚨 Si Necesitas Pagos en el Futuro

Cuando implementes pagos (con un proveedor colombiano):
1. Las tareas ECS con IPs públicas ya pueden acceder a internet
2. **NO necesitarás recrear el NAT Gateway**
3. Solo necesitarás habilitar el módulo de pagos

---

## 📝 Resumen de Comandos

```bash
# 1. Verificar IGW
aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=vpc-0c6e191050cee9035"

# 2. Actualizar servicio ECS (reemplaza sg-XXX con tu security group)
aws ecs update-service \
  --cluster backend-prod-cluster \
  --service vintage-music-backend-service \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-0749c393dceeada5c,subnet-0afad41238df3d96d],securityGroups=[sg-XXX],assignPublicIp=ENABLED}" \
  --force-new-deployment

# 3. Verificar que funciona
aws ecs describe-services --cluster backend-prod-cluster --services vintage-music-backend-service
```

---

**Última actualización**: Noviembre 2025




