.model small
.286
.data
a	dd ?
b	dd ?
value_s2f	dw	0			
buf	db 8,9 dup (0)
msga	db 'Enter a = $' 
msgb	db 13,10,'Enter b = $'	
msgc	db 13,10,'Result a + b = $'
.stack 256
.code
start:
	mov ax,@data	
	mov ds,ax
	mov ah,9		
	mov dx,offset msga		
	int 21h			
	call inputfloat
	fstp a
	mov ah,9		
	mov dx,offset msgb		
	int 21h			
	call inputfloat
	fstp b
	
	mov ah,9		
	mov dx,offset msgc		
	int 21h			
	fld a
	fadd b
	call outfloat
	
	mov ah,0	
	int 16h
	mov ax,4c00h	
	int 21h
inputfloat	proc
ina:
	mov ah,0ah		
	mov dx,offset buf		
	int 21h			
	mov si,offset buf+2		
	
	call STRTOFLOAT		
	jc ina			
	ret

inputfloat endp


outfloat proc   near
        push    ax
        push    cx
        push    dx


        push    bp
        mov     bp, sp
        push    10
        push    0

        ftst
        fstsw   ax
        sahf
        jnc     @of1

        mov     ah, 02h
        mov     dl, '-'
        int     21h
.
        fchs
  
      
@of1:   fld1                           
        fld     st(1)                  

        fprem                         

        fsub    st(2), st              
        fxch    st(2)               

        xor     cx, cx

@of2:   fidiv   word ptr [bp - 2]     
        fxch    st(1)                
        fld     st(1)                  

        fprem                         

        fsub    st(2), st          

        fimul   word ptr [bp - 2]     
        fistp   word ptr [bp - 4]      
        inc     cx ;+1, cx++ 

        push    word ptr [bp - 4]
        fxch    st(1)                 

        ftst 
        fstsw   ax
        sahf
        jnz     short @of2 

        mov     ah, 02h
@of3:   pop     dx

        add     dl, 30h
        int     21h

        loop    @of3                 

        fstp    st(0)                
        fxch    st(1)                 
        ftst
        fstsw   ax
        sahf
        jz      short @of5

        mov     ah, 02h
        mov     dl, '.'
        int     21h
.
        mov     cx, 6

@of4:   fimul   word ptr [bp - 2]      
        fxch    st(1)                  
        fld     st(1)                 

        fprem                         

        fsub    st(2), st              
        fxch    st(2)                  

        fistp   word ptr [bp - 4]      

        mov     ah, 02h
        mov     dl, [bp - 4]
        add     dl, 30h 
        int     21h

        fxch    st(1)                  
        ftst
        fstsw   ax
        sahf

        loopnz  @of4               

@of5:   fstp    st(0)                
        fstp    st(0)                

        leave
        pop     dx
        pop     cx
        pop     ax
        ret
outfloat endp

STRTOFLOAT	PROC
	jmp		@STARTCONVERSATION_S2F	
@STARTCONVERSATION_S2F:
	pusha
	mov		value_s2f, 0			
	xor		bx, bx				
	cmp	byte ptr [si], '-'		
	jne		@POSITIVE_S2F		
	inc		bx					
@POSITIVE_S2F:
	mov		value_s2f, 10		
	fild		value_s2f			
	fldz							
@REPEAT_BEFORE:
	mov		al, byte ptr si[bx]		
	cmp	al, byte ptr '.'			
	je		@ISPOINTBEFORE	
	cmp	al, byte ptr 13			
	je		@ENDASINT		
	cmp	al, '0'				
	jc	@END_S2F_ERR			
	cmp 	al,'9'
	ja	@END_S2F_ERR
	sub		al, 30h				
	mov		byte ptr value_s2f, al	
	fiadd	value_s2f			
	fmul	st(0), st(1)			
	inc		bx					
	jmp		@REPEAT_BEFORE
@ISPOINTBEFORE:
	inc		bx					
	fdiv		st(0), st(1)			
	fxch		st(1)				
	mov		al, byte ptr 13			
@FINDNEXT:
	cmp	si[bx], al				
	je		@FINDEND			
	inc		bx					
	jmp		@FINDNEXT			
@FINDEND:
	dec		bx					
	fldz							
@REPEAT_AFTER:
	mov		ax, word ptr si[bx]		
	cmp	al, byte ptr '.'			
	je		@WASPOINTAFTER	
	cmp	al, '0'			
	jc	@END_S2F_ERR          
	cmp 	al,'9'
	ja	@END_S2F_ERR
	sub		al, 30h				
	mov		byte ptr value_s2f, al	
	fiadd	value_s2f			
	fdiv		st(0), st(1)			
	dec		bx					
	loop	@REPEAT_AFTER
@WASPOINTAFTER:
	fxch		st(1)				
	fxch		st(2)				
	faddp	st(1)				
	fxch		st(1)				
	fistp		value_s2f			
	jmp		@FULLEND			
@ENDASINT:
	fdiv		st(0), st(1)			
	fxch		st(1)				
	fistp		value_s2f			
@FULLEND:
	cmp	byte ptr [si], '-'		
	jne		@END_S2F			
	fchs						
@END_S2F:
	popa						
	clc						
	ret							

@END_S2F_ERR:
	popa						
	fistp value_s2f				
	stc					
	ret							
STRTOFLOAT	ENDP

end start
