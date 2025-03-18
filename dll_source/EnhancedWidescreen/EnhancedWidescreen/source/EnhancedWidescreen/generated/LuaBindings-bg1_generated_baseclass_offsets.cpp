
#include "engine_structs_bg1.h"

template<typename Derived, typename Base>
constexpr uintptr_t offsetofbase() {
	return reinterpret_cast<uintptr_t>(static_cast<Base*>(reinterpret_cast<Derived*>(1))) - 1;
}

void registerBaseclasses() {
	RegisterBaseclassOffsets({
		{"CSize", {
			{"tagSIZE", offsetofbase<CSize, tagSIZE>()},
		}},
		{"CRect", {
			{"RECT", offsetofbase<CRect, RECT>()},
		}},
		{"CWarp", {
			{"CObject", offsetofbase<CWarp, CObject>()},
		}},
		{"CWarp::vtbl", {
			{"CObject::vtbl", offsetofbase<CWarp::vtbl, CObject::vtbl>()},
		}},
		{"CTypedPtrList<CPtrList,long>", {
			{"CObject", offsetofbase<CTypedPtrList<CPtrList,long>, CObject>()},
		}},
		{"CTypedPtrList<CPtrList,long>::vtbl", {
			{"CObject::vtbl", offsetofbase<CTypedPtrList<CPtrList,long>::vtbl, CObject::vtbl>()},
		}},
		{"CTypedPtrList<CPtrList,CWarp*>", {
			{"CObject", offsetofbase<CTypedPtrList<CPtrList,CWarp*>, CObject>()},
		}},
		{"CTypedPtrList<CPtrList,CWarp*>::vtbl", {
			{"CObject::vtbl", offsetofbase<CTypedPtrList<CPtrList,CWarp*>::vtbl, CObject::vtbl>()},
		}},
		{"CTypedPtrList<CPtrList,CUIPanel*>", {
			{"CObject", offsetofbase<CTypedPtrList<CPtrList,CUIPanel*>, CObject>()},
		}},
		{"CTypedPtrList<CPtrList,CUIPanel*>::vtbl", {
			{"CObject::vtbl", offsetofbase<CTypedPtrList<CPtrList,CUIPanel*>::vtbl, CObject::vtbl>()},
		}},
		{"CTypedPtrList<CPtrList,CUIControlBase*>", {
			{"CObject", offsetofbase<CTypedPtrList<CPtrList,CUIControlBase*>, CObject>()},
		}},
		{"CTypedPtrList<CPtrList,CUIControlBase*>::vtbl", {
			{"CObject::vtbl", offsetofbase<CTypedPtrList<CPtrList,CUIControlBase*>::vtbl, CObject::vtbl>()},
		}},
		{"CTypedPtrList<CPtrList,CGameEffect*>", {
			{"CObject", offsetofbase<CTypedPtrList<CPtrList,CGameEffect*>, CObject>()},
		}},
		{"CTypedPtrList<CPtrList,CGameEffect*>::vtbl", {
			{"CObject::vtbl", offsetofbase<CTypedPtrList<CPtrList,CGameEffect*>::vtbl, CObject::vtbl>()},
		}},
		{"CGameEffectList", {
			{"CTypedPtrList<CPtrList,CGameEffect*>", offsetofbase<CGameEffectList, CTypedPtrList<CPtrList,CGameEffect*>>()},
		}},
		{"CGameEffectList::vtbl", {
			{"CTypedPtrList<CPtrList,CGameEffect*>::vtbl", offsetofbase<CGameEffectList::vtbl, CTypedPtrList<CPtrList,CGameEffect*>::vtbl>()},
		}},
		{"CSyncObject", {
			{"CObject", offsetofbase<CSyncObject, CObject>()},
		}},
		{"CSyncObject::vtbl", {
			{"CObject::vtbl", offsetofbase<CSyncObject::vtbl, CObject::vtbl>()},
		}},
		{"CVidMode3", {
			{"CVidMode", offsetofbase<CVidMode3, CVidMode>()},
		}},
		{"CVidMode3::vtbl", {
			{"CVidMode::vtbl", offsetofbase<CVidMode3::vtbl, CVidMode::vtbl>()},
		}},
		{"CVidMode2", {
			{"CVidMode", offsetofbase<CVidMode2, CVidMode>()},
		}},
		{"CVidMode2::vtbl", {
			{"CVidMode::vtbl", offsetofbase<CVidMode2::vtbl, CVidMode::vtbl>()},
		}},
		{"CVidMode1", {
			{"CVidMode", offsetofbase<CVidMode1, CVidMode>()},
		}},
		{"CVidMode1::vtbl", {
			{"CVidMode::vtbl", offsetofbase<CVidMode1::vtbl, CVidMode::vtbl>()},
		}},
		{"CVidMode0", {
			{"CVidMode", offsetofbase<CVidMode0, CVidMode>()},
		}},
		{"CVidMode0::vtbl", {
			{"CVidMode::vtbl", offsetofbase<CVidMode0::vtbl, CVidMode::vtbl>()},
		}},
		{"CCriticalSection", {
			{"CSyncObject", offsetofbase<CCriticalSection, CSyncObject>()},
		}},
		{"CCriticalSection::vtbl", {
			{"CSyncObject::vtbl", offsetofbase<CCriticalSection::vtbl, CSyncObject::vtbl>()},
		}},
		{"CRes", {
			{"CObject", offsetofbase<CRes, CObject>()},
		}},
		{"CRes::vtbl", {
			{"CObject::vtbl", offsetofbase<CRes::vtbl, CObject::vtbl>()},
		}},
		{"CResWED", {
			{"CRes", offsetofbase<CResWED, CRes>()},
		}},
		{"CResWED::vtbl", {
			{"CRes::vtbl", offsetofbase<CResWED::vtbl, CRes::vtbl>()},
		}},
		{"CResUI", {
			{"CRes", offsetofbase<CResUI, CRes>()},
		}},
		{"CResUI::vtbl", {
			{"CRes::vtbl", offsetofbase<CResUI::vtbl, CRes::vtbl>()},
		}},
		{"CResText", {
			{"CRes", offsetofbase<CResText, CRes>()},
		}},
		{"CResText::vtbl", {
			{"CRes::vtbl", offsetofbase<CResText::vtbl, CRes::vtbl>()},
		}},
		{"CResMosaic", {
			{"CRes", offsetofbase<CResMosaic, CRes>()},
		}},
		{"CResMosaic::vtbl", {
			{"CRes::vtbl", offsetofbase<CResMosaic::vtbl, CRes::vtbl>()},
		}},
		{"CResItem", {
			{"CRes", offsetofbase<CResItem, CRes>()},
		}},
		{"CResItem::vtbl", {
			{"CRes::vtbl", offsetofbase<CResItem::vtbl, CRes::vtbl>()},
		}},
		{"CResEffect", {
			{"CRes", offsetofbase<CResEffect, CRes>()},
		}},
		{"CResEffect::vtbl", {
			{"CRes::vtbl", offsetofbase<CResEffect::vtbl, CRes::vtbl>()},
		}},
		{"CResCell", {
			{"CRes", offsetofbase<CResCell, CRes>()},
		}},
		{"CResCell::vtbl", {
			{"CRes::vtbl", offsetofbase<CResCell::vtbl, CRes::vtbl>()},
		}},
		{"CMessageVisualEffect", {
			{"CMessage", offsetofbase<CMessageVisualEffect, CMessage>()},
		}},
		{"CMessageVisualEffect::vtbl", {
			{"CMessage::vtbl", offsetofbase<CMessageVisualEffect::vtbl, CMessage::vtbl>()},
		}},
		{"CMessageUnknown", {
			{"CMessage", offsetofbase<CMessageUnknown, CMessage>()},
		}},
		{"CMessageUnknown::vtbl", {
			{"CMessage::vtbl", offsetofbase<CMessageUnknown::vtbl, CMessage::vtbl>()},
		}},
		{"CMessageAutoScroll", {
			{"CMessage", offsetofbase<CMessageAutoScroll, CMessage>()},
		}},
		{"CMessageAutoScroll::vtbl", {
			{"CMessage::vtbl", offsetofbase<CMessageAutoScroll::vtbl, CMessage::vtbl>()},
		}},
		{"CMessageAddEffect", {
			{"CMessage", offsetofbase<CMessageAddEffect, CMessage>()},
		}},
		{"CMessageAddEffect::vtbl", {
			{"CMessage::vtbl", offsetofbase<CMessageAddEffect::vtbl, CMessage::vtbl>()},
		}},
		{"CGameAnimationTypeCharacter", {
			{"CGameAnimationType", offsetofbase<CGameAnimationTypeCharacter, CGameAnimationType>()},
		}},
		{"CGameAnimationTypeCharacter::vtbl", {
			{"CGameAnimationType::vtbl", offsetofbase<CGameAnimationTypeCharacter::vtbl, CGameAnimationType::vtbl>()},
		}},
		{"CVidCell", {
			{"CVidImage", offsetofbase<CVidCell, CVidImage>()},
			{"CResHelper<CResCell,1000>", offsetofbase<CVidCell, CResHelper<CResCell,1000>>()},
		}},
		{"CVidFont", {
			{"CVidCell", offsetofbase<CVidFont, CVidCell>()},
		}},
		{"CUIControlButton", {
			{"CUIControlBase", offsetofbase<CUIControlButton, CUIControlBase>()},
		}},
		{"CGameEffectFile", {
			{"CResHelper<CResEffect,1016>", offsetofbase<CGameEffectFile, CResHelper<CResEffect,1016>>()},
		}},
		{"CVidMosaic", {
			{"CVidImage", offsetofbase<CVidMosaic, CVidImage>()},
			{"CResHelper<CResMosaic,1004>", offsetofbase<CVidMosaic, CResHelper<CResMosaic,1004>>()},
		}},
		{"CUIControlButtonMap", {
			{"CUIControlButton", offsetofbase<CUIControlButtonMap, CUIControlButton>()},
		}},
		{"CUIControlButtonMap::vtbl", {
			{"CUIControlButton::vtbl", offsetofbase<CUIControlButtonMap::vtbl, CUIControlButton::vtbl>()},
		}},
		{"CUIControlTextField", {
			{"CUIControlBase", offsetofbase<CUIControlTextField, CUIControlBase>()},
		}},
		{"CUIControlTextField::vtbl", {
			{"CUIControlBase::vtbl", offsetofbase<CUIControlTextField::vtbl, CUIControlBase::vtbl>()},
		}},
		{"CItem", {
			{"CResHelper<CResItem,1005>", offsetofbase<CItem, CResHelper<CResItem,1005>>()},
		}},
		{"C2DArray", {
			{"CResHelper<CResText,1012>", offsetofbase<C2DArray, CResHelper<CResText,1012>>()},
		}},
		{"CBaldurEngine", {
			{"CWarp", offsetofbase<CBaldurEngine, CWarp>()},
		}},
		{"CBaldurEngine::vtbl", {
			{"CWarp::vtbl", offsetofbase<CBaldurEngine::vtbl, CWarp::vtbl>()},
		}},
		{"CBaldurProjector", {
			{"CBaldurEngine", offsetofbase<CBaldurProjector, CBaldurEngine>()},
		}},
		{"CBaldurProjector::vtbl", {
			{"CBaldurEngine::vtbl", offsetofbase<CBaldurProjector::vtbl, CBaldurEngine::vtbl>()},
		}},
		{"CScreenConnection", {
			{"CBaldurEngine", offsetofbase<CScreenConnection, CBaldurEngine>()},
		}},
		{"CScreenConnection::vtbl", {
			{"CBaldurEngine::vtbl", offsetofbase<CScreenConnection::vtbl, CBaldurEngine::vtbl>()},
		}},
		{"CScreenMap", {
			{"CBaldurEngine", offsetofbase<CScreenMap, CBaldurEngine>()},
		}},
		{"CScreenMap::vtbl", {
			{"CBaldurEngine::vtbl", offsetofbase<CScreenMap::vtbl, CBaldurEngine::vtbl>()},
		}},
		{"CScreenWorldMap", {
			{"CBaldurEngine", offsetofbase<CScreenWorldMap, CBaldurEngine>()},
		}},
		{"CScreenWorldMap::vtbl", {
			{"CBaldurEngine::vtbl", offsetofbase<CScreenWorldMap::vtbl, CBaldurEngine::vtbl>()},
		}},
		{"CUnknownEngine11", {
			{"CBaldurEngine", offsetofbase<CUnknownEngine11, CBaldurEngine>()},
		}},
		{"CUnknownEngine11::vtbl", {
			{"CBaldurEngine::vtbl", offsetofbase<CUnknownEngine11::vtbl, CBaldurEngine::vtbl>()},
		}},
		{"CUnknownEngine12", {
			{"CBaldurEngine", offsetofbase<CUnknownEngine12, CBaldurEngine>()},
		}},
		{"CUnknownEngine12::vtbl", {
			{"CBaldurEngine::vtbl", offsetofbase<CUnknownEngine12::vtbl, CBaldurEngine::vtbl>()},
		}},
		{"CUnknownEngine13", {
			{"CBaldurEngine", offsetofbase<CUnknownEngine13, CBaldurEngine>()},
		}},
		{"CUnknownEngine13::vtbl", {
			{"CBaldurEngine::vtbl", offsetofbase<CUnknownEngine13::vtbl, CBaldurEngine::vtbl>()},
		}},
		{"CUnknownEngine14", {
			{"CBaldurEngine", offsetofbase<CUnknownEngine14, CBaldurEngine>()},
		}},
		{"CUnknownEngine14::vtbl", {
			{"CBaldurEngine::vtbl", offsetofbase<CUnknownEngine14::vtbl, CBaldurEngine::vtbl>()},
		}},
		{"CUnknownEngine15", {
			{"CBaldurEngine", offsetofbase<CUnknownEngine15, CBaldurEngine>()},
		}},
		{"CUnknownEngine15::vtbl", {
			{"CBaldurEngine::vtbl", offsetofbase<CUnknownEngine15::vtbl, CBaldurEngine::vtbl>()},
		}},
		{"CUnknownEngine16", {
			{"CBaldurEngine", offsetofbase<CUnknownEngine16, CBaldurEngine>()},
		}},
		{"CUnknownEngine16::vtbl", {
			{"CBaldurEngine::vtbl", offsetofbase<CUnknownEngine16::vtbl, CBaldurEngine::vtbl>()},
		}},
		{"CUnknownEngine17", {
			{"CBaldurEngine", offsetofbase<CUnknownEngine17, CBaldurEngine>()},
		}},
		{"CUnknownEngine17::vtbl", {
			{"CBaldurEngine::vtbl", offsetofbase<CUnknownEngine17::vtbl, CBaldurEngine::vtbl>()},
		}},
		{"CUnknownEngine18", {
			{"CBaldurEngine", offsetofbase<CUnknownEngine18, CBaldurEngine>()},
		}},
		{"CUnknownEngine18::vtbl", {
			{"CBaldurEngine::vtbl", offsetofbase<CUnknownEngine18::vtbl, CBaldurEngine::vtbl>()},
		}},
		{"CUnknownEngine19", {
			{"CBaldurEngine", offsetofbase<CUnknownEngine19, CBaldurEngine>()},
		}},
		{"CUnknownEngine19::vtbl", {
			{"CBaldurEngine::vtbl", offsetofbase<CUnknownEngine19::vtbl, CBaldurEngine::vtbl>()},
		}},
		{"CUnknownEngine2", {
			{"CBaldurEngine", offsetofbase<CUnknownEngine2, CBaldurEngine>()},
		}},
		{"CUnknownEngine2::vtbl", {
			{"CBaldurEngine::vtbl", offsetofbase<CUnknownEngine2::vtbl, CBaldurEngine::vtbl>()},
		}},
		{"CUnknownEngine4", {
			{"CBaldurEngine", offsetofbase<CUnknownEngine4, CBaldurEngine>()},
		}},
		{"CUnknownEngine4::vtbl", {
			{"CBaldurEngine::vtbl", offsetofbase<CUnknownEngine4::vtbl, CBaldurEngine::vtbl>()},
		}},
		{"CUnknownEngine5", {
			{"CBaldurEngine", offsetofbase<CUnknownEngine5, CBaldurEngine>()},
		}},
		{"CUnknownEngine5::vtbl", {
			{"CBaldurEngine::vtbl", offsetofbase<CUnknownEngine5::vtbl, CBaldurEngine::vtbl>()},
		}},
		{"CUnknownEngine6", {
			{"CBaldurEngine", offsetofbase<CUnknownEngine6, CBaldurEngine>()},
		}},
		{"CUnknownEngine6::vtbl", {
			{"CBaldurEngine::vtbl", offsetofbase<CUnknownEngine6::vtbl, CBaldurEngine::vtbl>()},
		}},
		{"CUnknownEngine7", {
			{"CBaldurEngine", offsetofbase<CUnknownEngine7, CBaldurEngine>()},
		}},
		{"CUnknownEngine7::vtbl", {
			{"CBaldurEngine::vtbl", offsetofbase<CUnknownEngine7::vtbl, CBaldurEngine::vtbl>()},
		}},
		{"CUnknownEngine8", {
			{"CBaldurEngine", offsetofbase<CUnknownEngine8, CBaldurEngine>()},
		}},
		{"CUnknownEngine8::vtbl", {
			{"CBaldurEngine::vtbl", offsetofbase<CUnknownEngine8::vtbl, CBaldurEngine::vtbl>()},
		}},
		{"CUnknownEngine9", {
			{"CBaldurEngine", offsetofbase<CUnknownEngine9, CBaldurEngine>()},
		}},
		{"CUnknownEngine9::vtbl", {
			{"CBaldurEngine::vtbl", offsetofbase<CUnknownEngine9::vtbl, CBaldurEngine::vtbl>()},
		}},
		{"CScreenWorld", {
			{"CBaldurEngine", offsetofbase<CScreenWorld, CBaldurEngine>()},
		}},
		{"CScreenWorld::vtbl", {
			{"CBaldurEngine::vtbl", offsetofbase<CScreenWorld::vtbl, CBaldurEngine::vtbl>()},
		}},
		{"CGameEffect", {
			{"CGameEffectBase", offsetofbase<CGameEffect, CGameEffectBase>()},
		}},
		{"CBaldurChitin", {
			{"CChitin", offsetofbase<CBaldurChitin, CChitin>()},
		}},
		{"CBaldurChitin::vtbl", {
			{"CChitin::vtbl", offsetofbase<CBaldurChitin::vtbl, CChitin::vtbl>()},
		}},
		{"CProjectile", {
			{"CGameObject", offsetofbase<CProjectile, CGameObject>()},
		}},
		{"CProjectile::vtbl", {
			{"CGameObject::vtbl", offsetofbase<CProjectile::vtbl, CGameObject::vtbl>()},
		}},
		{"CProjectileMagicMissile", {
			{"CProjectile", offsetofbase<CProjectileMagicMissile, CProjectile>()},
		}},
		{"CProjectileMagicMissile::vtbl", {
			{"CProjectile::vtbl", offsetofbase<CProjectileMagicMissile::vtbl, CProjectile::vtbl>()},
		}},
		{"CGameAIBase", {
			{"CGameObject", offsetofbase<CGameAIBase, CGameObject>()},
		}},
		{"CGameAIBase::vtbl", {
			{"CGameObject::vtbl", offsetofbase<CGameAIBase::vtbl, CGameObject::vtbl>()},
		}},
		{"CGameSprite", {
			{"CGameAIBase", offsetofbase<CGameSprite, CGameAIBase>()},
		}},
	});
}

