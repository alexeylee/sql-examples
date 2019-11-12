CREATE  PROCEDURE [clearing].[prc_create_outgoing_claim_confirm_message] 
	@caseDocId INT,
	@returnMessage VARCHAR(1024) = ''  OUTPUT		
AS
BEGIN
	DECLARE @errorCode INT;
	DECLARE @errorStep VARCHAR(200);
	
	DECLARE @outgoingClaimId INT;
	DECLARE @initiatorParticipantId INT;	
	DECLARE @initialParticipantCode VARCHAR(12);
	
	DECLARE @messageType VARCHAR(3);
	DECLARE @msgUserPriority VARCHAR(4);
	DECLARE @outgoingMessageId INT;
	DECLARE @confirmTypeConst VARCHAR(4);
	DECLARE @claimConfirmId INT;
	DECLARE @createDateTime DATETIME;
	
	DECLARE @evenInfo VARCHAR(128);
	DECLARE @eventCode VARCHAR(128);
		
	SET @initialParticipantCode = 'PARXRUMOXXXX';
	SET @messageType = 'XAP';
	SET @msgUserPriority = '0020';	
	SET @eventCode = 'claim_confirm';
	SET @confirmTypeConst = 'AUTH';
	SET @createDateTime = CURRENT_TIMESTAMP;

	SET @errorCode = @@ERROR
	BEGIN TRY	
		BEGIN TRAN

			SET @errorStep = 'select claim id';
			 
			SELECT TOP 1
				@outgoingClaimId = oc.id
			FROM 
				loss.tbl_request_pvu trp
				INNER JOIN 
				clearing.claim_base cb ON cb.claim_id = cast (trp.doc_id AS VARCHAR(19))
				INNER JOIN 
				clearing.outgoing_claim oc ON oc.ref_general = cb.id
				INNER JOIN 
				clearing.message_flow mf ON mf.ref_message = oc.ref_message
			WHERE 
				trp.doc_id = @caseDocId --AND mf.ref_confirmation IS NOT NULL 
			ORDER BY 
				cb.id DESC
								
			SELECT @initiatorParticipantId = id_company 
			FROM clearing.d_participant 
			WHERE participant_code = @initialParticipantCode;
					
			-- create outgoing message			
			SET @errorStep = 'create outgoing message';
			EXECUTE clearing.prc_create_outgoing_message
				@type = @messageType,
				@msgUserPriority = @msgUserPriority,
				@createdMessageId = @outgoingMessageId OUTPUT;
				
			INSERT INTO clearing.claim_confirm (ref_outgoing_claim, ref_outgoing_message, [type], ref_initiator_participant, create_date_time)
			VALUES(@outgoingClaimId, @outgoingMessageId, @confirmTypeConst, @initiatorParticipantId, @createDateTime);
			SELECT @claimConfirmId = SCOPE_IDENTITY();
		
		COMMIT TRAN	
		
		BEGIN TRAN
			SET @errorStep = 'add event';
			SET @evenInfo = CAST(@claimConfirmId AS VARCHAR(128));
			EXECUTE clearing.prc_add_event
				@code = @eventCode,
				@info = @evenInfo;			
		COMMIT TRAN
		SELECT  @errorCode  = 0, @returnMessage = 'Message created';
		RETURN @errorCode;				
	END TRY
	BEGIN CATCH
	
		IF @@TRANCOUNT > 0 ROLLBACK

		SELECT 
			@errorCode = ERROR_NUMBER()
		   ,@returnMessage =  '[error] [' + ERROR_PROCEDURE() + '] => error_number: ' +
				+ cast(ERROR_NUMBER() as varchar(20)) + ', state: '
				+ CAST(ERROR_STATE() AS varchar(20)) + ', line: '
				+ cast(ERROR_LINE() as varchar(20)) + ', error_text: ' 
				+ @errorStep + ';  '  
				+ ERROR_MESSAGE();         

		RETURN @errorCode;
	END CATCH			
END

