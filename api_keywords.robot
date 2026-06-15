*** Settings ***
# resources/keywords/api_keywords.robot
Documentation     Keywords para testes de API em sistemas financeiros e de seguro.
...               Baseado em experiências reais no Banco C6 e AGF.

Library           RequestsLibrary
Library           Collections
Library           String
Library           DateTime
Library           OperatingSystem


*** Variables ***
${BASE_URL_DEV}     https://api-dev.seuapp.com
${BASE_URL_QA}      https://api-qa.seuapp.com
${BASE_URL_HML}     https://api-hml.seuapp.com
${DEFAULT_TIMEOUT}  30


*** Keywords ***

# ── SESSÃO ─────────────────────────────────────────────────────────────────

Criar Sessão API
    [Documentation]    Inicializa sessão HTTP reutilizável para o ambiente informado.
    [Arguments]        ${env}=qa    ${verify_ssl}=${TRUE}
    ${base_url}=       Get Variable Value    ${BASE_URL_${env.upper()}}
    Create Session     api    ${base_url}    verify=${verify_ssl}    timeout=${DEFAULT_TIMEOUT}
    Log               Sessão criada: ${base_url}    INFO

Autenticar Usuário
    [Documentation]    Realiza login e retorna token JWT.
    [Arguments]        ${email}    ${password}
    ${payload}=        Create Dictionary    email=${email}    password=${password}
    ${response}=       POST On Session    api    /auth/login    json=${payload}
    Status Should Be   200    ${response}
    ${token}=          Set Variable    ${response.json()}[token]
    [Return]           ${token}

Criar Headers Autenticados
    [Documentation]    Retorna dicionário de headers com Bearer token.
    [Arguments]        ${token}
    ${headers}=        Create Dictionary
    ...                Authorization=Bearer ${token}
    ...                Content-Type=application/json
    [Return]           ${headers}


# ── CONTRATAÇÃO ────────────────────────────────────────────────────────────

Contratar Produto
    [Documentation]    Realiza contratação de produto de seguro via API.
    ...                Retorna o ID do contrato criado.
    [Arguments]        ${headers}    ${produto_id}    ${dados_segurado}
    ${payload}=        Create Dictionary
    ...                produtoId=${produto_id}
    ...                segurado=${dados_segurado}
    ...                dataVigencia=${NEXT_MONTH_DATE}
    ${response}=       POST On Session    api    /contratos    json=${payload}    headers=${headers}
    Status Should Be   201    ${response}
    Dictionary Should Contain Key    ${response.json()}    contratoId
    ${contrato_id}=    Set Variable    ${response.json()}[contratoId]
    Log               Contrato criado: ${contrato_id}    INFO
    [Return]           ${contrato_id}

Validar Status Contrato
    [Documentation]    Valida o status atual de um contrato.
    [Arguments]        ${headers}    ${contrato_id}    ${status_esperado}
    ${response}=       GET On Session    api    /contratos/${contrato_id}    headers=${headers}
    Status Should Be   200    ${response}
    ${status_atual}=   Set Variable    ${response.json()}[status]
    Should Be Equal    ${status_atual}    ${status_esperado}
    ...                msg=Status do contrato divergente. Esperado: ${status_esperado} | Atual: ${status_atual}
    [Return]           ${response.json()}

Cancelar Contrato
    [Documentation]    Cancela um contrato ativo e valida status resultante.
    [Arguments]        ${headers}    ${contrato_id}    ${motivo}=SOLICITACAO_CLIENTE
    ${payload}=        Create Dictionary    motivo=${motivo}
    ${response}=       POST On Session
    ...                api    /contratos/${contrato_id}/cancelar
    ...                json=${payload}    headers=${headers}
    Status Should Be   200    ${response}
    Validar Status Contrato    ${headers}    ${contrato_id}    CANCELADO
    Log               Contrato ${contrato_id} cancelado com sucesso.    INFO


# ── BILLING ────────────────────────────────────────────────────────────────

Validar Geração De Boleto
    [Documentation]    Verifica se o boleto foi gerado corretamente após contratação.
    [Arguments]        ${headers}    ${contrato_id}
    ${response}=       GET On Session    api    /billing/contratos/${contrato_id}    headers=${headers}
    Status Should Be   200    ${response}
    ${billing}=        Set Variable    ${response.json()}
    Dictionary Should Contain Key    ${billing}    boletoUrl
    Dictionary Should Contain Key    ${billing}    vencimento
    Dictionary Should Contain Key    ${billing}    valor
    Should Not Be Empty    ${billing}[boletoUrl]
    Log               Boleto gerado: ${billing}[boletoUrl]    INFO
    [Return]           ${billing}


# ── UTILITÁRIOS ────────────────────────────────────────────────────────────

Gerar CPF Válido
    [Documentation]    Gera um CPF válido para uso em testes.
    ${timestamp}=      Get Current Date    result_format=%f
    ${cpf}=            Evaluate    __import__('random').randint(100,999999999)
    [Return]           ${cpf:011d}

Aguardar Processamento
    [Documentation]    Aguarda processamento assíncrono com polling.
    [Arguments]        ${headers}    ${endpoint}    ${campo}    ${valor_esperado}
    ...                ${timeout}=60    ${intervalo}=5
    ${inicio}=         Get Current Date    result_format=epoch
    WHILE    True
        ${response}=     GET On Session    api    ${endpoint}    headers=${headers}
        ${valor_atual}=  Set Variable    ${response.json()}[${campo}]
        IF    '${valor_atual}' == '${valor_esperado}'
            Log    Campo '${campo}' atingiu valor esperado: ${valor_esperado}    INFO
            BREAK
        END
        ${agora}=        Get Current Date    result_format=epoch
        IF    ${agora} - ${inicio} > ${timeout}
            Fail    Timeout: campo '${campo}' não atingiu '${valor_esperado}' em ${timeout}s
        END
        Sleep    ${intervalo}
    END
